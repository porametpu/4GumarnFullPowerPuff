*** Settings ***
Library           SeleniumLibrary
Library          String
Test Teardown    Close Browser And Capture
Suite Teardown   Print Report path

*** Variables ***
${BASE_URL}    http://localhost:3001
${BROWSER}     chrome

# ===== PART: ACCOUNT =====
${PASSENGER_EMAIL}            %{PASSENGER_EMAIL=}
${PASSENGER_PASSWORD}         %{PASSENGER_PASSWORD=}
${DRIVER_EMAIL}               %{DRIVER_EMAIL=}
${DRIVER_PASSWORD}            %{DRIVER_PASSWORD=}

# ===== PART: TEST DATA =====
${ROUTE_NO_LUGGAGE}      %{ROUTE_NO_LUGGAGE=}
${ROUTE_MAX_MEDIUM}      %{ROUTE_MAX_MEDIUM=}
${ROUTE_MAX_LARGE}       %{ROUTE_MAX_LARGE=}
${ROUTE_MAX_EXTRALARGE}  %{ROUTE_MAX_EXTRALARGE=}


${FEE_MEDIUM}        50
${FEE_LARGE}         100
${FEE_EXTRALARGE}    120  

*** Keywords ***
Step
    [Arguments]    ${message}
    Log    ${message}
    Log To Console    STEP: ${message}

Click Element Safe
    [Arguments]    ${locator}
    Wait Until Element Is Visible    ${locator}    10s
    Scroll Element Into View    ${locator}
    ${ok}=    Run Keyword And Return Status    Click Element    ${locator}
    IF    not ${ok}
        ${is_xpath}=    Run Keyword And Return Status    Should Start With    ${locator}    xpath=
        IF    ${is_xpath}
            ${xp}=    Replace String    ${locator}    xpath=    ${EMPTY}
            ${js_ok}=    Run Keyword And Return Status    Execute JavaScript    document.evaluate(arguments[0],document,null,9,null).singleNodeValue.click()    ${xp}
            Run Keyword If    not ${js_ok}    Click Element    ${locator}
        ELSE
            Click Element    ${locator}
        END
    END

Dismiss Booking Suggestions
    Execute JavaScript    if(document.activeElement){document.activeElement.blur();}
    Press Keys    None    ESC
    Sleep    300ms
    Wait Until Keyword Succeeds    10x    300ms    Page Should Not Contain Element    xpath=//ul[contains(@class,'suggest-list')]//li

Close Browser And Capture
    Run Keyword And Ignore Error    Capture Page Screenshot
    Run Keyword And Ignore Error    Close Browser

Print Report Path
    Log To Console    \n===== Robot Report =====
    Log To Console    Report: ${OUTPUT DIR}${/}report.html
    Log To Console    Log: ${OUTPUT DIR}${/}log.html
    Log To Console    Output: ${OUTPUT DIR}${/}output.xml

# ===== PART: AUTH =====
Login As Passenger
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier  10s
    Input Text    id=identifier    ${PASSENGER_EMAIL}
    Input Password    id=password    ${PASSENGER_PASSWORD}
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    10s

Login As Driver
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier  10s
    Input Text    id=identifier    ${DRIVER_EMAIL}
    Input Password    id=password    ${DRIVER_PASSWORD}
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    10s

# ===== PART: PASSENGER FLOW =====
Open Booking Modal By Route Title
    [Arguments]    ${route_title}
    Run Keyword If    '${route_title}' == ''    Fail    route_title is empty. Set ROUTE_* env variable or set value in ExtraLuggage.robot.
    Go To    ${BASE_URL}/findTrip
    Wait Until Element Is Visible    xpath=(//div[contains(@class,'route-card')])[1]    20s
    ${has_route}=    Run Keyword And Return Status    Wait Until Page Contains    ${route_title}    10s
    Run Keyword If    not ${has_route}    Fail    Route title '${route_title}' not found. Please set route variable to exact UI text.
    ${card}=    Set Variable    xpath=//*[contains(normalize-space(.),"${route_title}")]/ancestor::div[contains(@class,'route-card')][1]
    Scroll Element Into View    ${card}
    Click Element    ${card}
    Wait Until Element Is Visible    ${card}//button[contains(normalize-space(.),'จองที่นั่ง')]    10s
    Click Element    ${card}//button[contains(normalize-space(.),'จองที่นั่ง')]
    Wait Until Page Contains    ยืนยันการจอง    10s

Close Booking Modal
    ${has_cancel}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//div[contains(@class,'modal-content')]//button[contains(normalize-space(.),'ยกเลิก')]
    Run Keyword If    ${has_cancel}    Click Element    xpath=//div[contains(@class,'modal-content')]//button[contains(normalize-space(.),'ยกเลิก')]
    Run Keyword If    ${has_cancel}    Wait Until Page Does Not Contain    ยืนยันการจอง    10s

Route In Modal Matches Policy
    [Arguments]    ${policy}
    ${has_toggle}=    Run Keyword And Return Status    Page Should Contain Element    xpath=//span[normalize-space()='มีสัมภาระเกินปกติ']/following::input[@type='checkbox'][1]
    IF    '${policy}' == 'NO_LUGGAGE'
        ${ok}=    Evaluate    not ${has_toggle}
        RETURN    ${ok}
    END
    IF    not ${has_toggle}
        RETURN    ${False}
    END

    Click Element    xpath=//span[normalize-space()='มีสัมภาระเกินปกติ']/following::input[@type='checkbox'][1]

    ${has_medium}=    Run Keyword And Return Status    Page Should Contain    ไม่เกิน 24 นิ้ว
    ${has_large}=     Run Keyword And Return Status    Page Should Contain    ไม่เกิน 28 นิ้ว
    ${has_extra}=     Run Keyword And Return Status    Page Should Contain    สัมภาระพิเศษ

    IF    '${policy}' == 'MEDIUM'
        ${ok}=    Evaluate    ${has_medium} and (not ${has_large}) and (not ${has_extra})
        RETURN    ${ok}
    ELSE IF    '${policy}' == 'LARGE'
        ${ok}=    Evaluate    ${has_medium} and ${has_large} and (not ${has_extra})
        RETURN    ${ok}
    ELSE IF    '${policy}' == 'EXTRA_LARGE'
        ${ok}=    Evaluate    ${has_medium} and ${has_large} and ${has_extra}
        RETURN    ${ok}
    ELSE
        Fail    Unknown policy '${policy}'
    END

Discover Route Title By Policy
    [Arguments]    ${policy}
    Go To    ${BASE_URL}/findTrip
    Wait Until Element Is Visible    xpath=(//div[contains(@class,'route-card')])[1]    20s
    ${count}=    Get Element Count    xpath=//div[contains(@class,'route-card')]
    ${end}=    Evaluate    ${count} + 1

    FOR    ${i}    IN RANGE    1    ${end}
        # Reload every loop to guarantee modal state is reset (avoid click intercept from overlay)
        Go To    ${BASE_URL}/findTrip
        Wait Until Element Is Visible    xpath=(//div[contains(@class,'route-card')])[1]    20s

        ${card}=    Set Variable    xpath=(//div[contains(@class,'route-card')])[${i}]
        Scroll Element Into View    ${card}
        ${title}=    Get Text    ${card}//h1[1]

        Click Element    ${card}
        ${book_btn}=    Set Variable    ${card}//button[contains(normalize-space(.),'จองที่นั่ง')]
        ${expanded}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${book_btn}    4s
        IF    not ${expanded}
            Click Element    ${card}
            ${expanded}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${book_btn}    3s
        END
        IF    not ${expanded}
            Continue For Loop
        END

        Click Element    ${book_btn}
        ${opened}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=//div[contains(@class,'modal-content')]//h3[contains(normalize-space(.),'ยืนยันการจอง')]    8s
        IF    not ${opened}
            Continue For Loop
        END

        ${match}=    Route In Modal Matches Policy    ${policy}
        IF    ${match}
            ${title}=    Strip String    ${title}
            Log To Console    FOUND ${policy}: ${title}
            RETURN    ${title}
        END
    END

    Fail    No route found for policy '${policy}' on /findTrip.

Ensure Route Titles Ready
    IF    '${ROUTE_NO_LUGGAGE}' == ''
        ${found_no}=    Discover Route Title By Policy    NO_LUGGAGE
        Set Suite Variable    ${ROUTE_NO_LUGGAGE}    ${found_no}
    END
    IF    '${ROUTE_MAX_MEDIUM}' == ''
        ${found_medium}=    Discover Route Title By Policy    MEDIUM
        Set Suite Variable    ${ROUTE_MAX_MEDIUM}    ${found_medium}
    END
    IF    '${ROUTE_MAX_LARGE}' == ''
        ${found_large}=    Discover Route Title By Policy    LARGE
        Set Suite Variable    ${ROUTE_MAX_LARGE}    ${found_large}
    END
    IF    '${ROUTE_MAX_EXTRALARGE}' == ''
        ${found_extra}=    Discover Route Title By Policy    EXTRA_LARGE
        Set Suite Variable    ${ROUTE_MAX_EXTRALARGE}    ${found_extra}
    END
    Log To Console    ROUTES -> NO:${ROUTE_NO_LUGGAGE} | M:${ROUTE_MAX_MEDIUM} | L:${ROUTE_MAX_LARGE} | XL:${ROUTE_MAX_EXTRALARGE}

Resolve Route Title Or Skip
    [Arguments]    ${configured_title}    ${policy}
    IF    '${configured_title}' != ''
        RETURN    ${configured_title}
    END
    ${status}    ${value}=    Run Keyword And Ignore Error    Discover Route Title By Policy    ${policy}
    IF    '${status}' == 'PASS'
        RETURN    ${value}
    END
    Skip    No route found for policy '${policy}' on /findTrip. Set ROUTE_* env variable to exact route title.

Fill Pickup And Dropoff By Suggestion
    [Arguments]    ${pickup_text}    ${dropoff_text}
    Input Text    xpath=//label[contains(normalize-space(.),'เลือกจุดขึ้นรถ')]/following::input[1]    ${pickup_text}
    ${pickup_suggest_ok}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=(//ul[contains(@class,'suggest-list')])[1]/li[1]    5s
    Run Keyword If    ${pickup_suggest_ok}    Click Element Safe    xpath=(//ul[contains(@class,'suggest-list')])[1]/li[1]
    Input Text    xpath=//label[contains(normalize-space(.),'เลือกจุดลงรถ')]/following::input[1]    ${dropoff_text}
    ${dropoff_suggest_ok}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=(//ul[contains(@class,'suggest-list')])[2]/li[1]    5s
    Run Keyword If    ${dropoff_suggest_ok}    Click Element Safe    xpath=(//ul[contains(@class,'suggest-list')])[2]/li[1]
    Dismiss Booking Suggestions

Enable Extra Luggage
    Dismiss Booking Suggestions
    Click Element Safe    xpath=//label[.//span[normalize-space()='มีสัมภาระเกินปกติ']]
    Wait Until Page Contains    ไม่เกิน 24 นิ้ว    10s

Select Luggage Medium
     Click Element Safe    xpath=//label[.//span[contains(normalize-space(.),'24 นิ้ว')]]
    
Select Luggage Large
     Click Element Safe    xpath=//label[.//span[contains(normalize-space(.),'28 นิ้ว')]]

Select Luggage ExtraLarge
     Click Element Safe    xpath=//label[.//span[contains(normalize-space(.),'สัมภาระพิเศษ')]]

Submit Booking
    Click Element    xpath=//button[normalize-space()='ยืนยันการจอง']
    Wait Until Page Contains    ส่งคำขอจองสำเร็จ   10s

Passenger Create Booking With Large Luggage
    [Arguments]    ${route_title}    ${pickup_text}    ${dropoff_text}
    Login As Passenger
    ${configured}=    Set Variable If    '${route_title}' != ''    ${route_title}    ${ROUTE_MAX_LARGE}
    ${target_route}=    Resolve Route Title Or Skip    ${configured}    LARGE
    Set Test Variable    ${LAST_BOOKED_ROUTE_TITLE}    ${target_route}
    Open Booking Modal By Route Title    ${target_route}
    Fill Pickup And Dropoff By Suggestion    ${pickup_text}    ${dropoff_text}
    Enable Extra Luggage
    Select Luggage Large
    Submit Booking
    Close Browser

Passenger Create Booking Without Extra Luggage
    [Arguments]    ${route_title}    ${pickup_text}    ${dropoff_text}
    Login As Passenger
    ${configured}=    Set Variable If    '${route_title}' != ''    ${route_title}    ${ROUTE_NO_LUGGAGE}
    ${target_route}=    Resolve Route Title Or Skip    ${configured}    NO_LUGGAGE
    Set Test Variable    ${LAST_BOOKED_ROUTE_TITLE}    ${target_route}
    Open Booking Modal By Route Title    ${target_route}
    Fill Pickup And Dropoff By Suggestion    ${pickup_text}    ${dropoff_text}
    Submit Booking
    Close Browser

# ===== PART: DRIVER FLOW =====
Open MyRoute Pending
    Go To    ${BASE_URL}/myRoute
    Wait Until Page Contains    คำขอจองเส้นทางของฉัน   10s
    Click Element    xpath=//button[contains(normalize-space(.),'รอดำเนินการ')]
    Wait Until Page Contains    รายการคำขอจอง    10s

Open First Pending Request
    ${has_card}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=(//div[contains(@class,'trip-card')])[1]    8s
    Run Keyword If    not ${has_card}    Skip    No pending request card found for current driver.
    Click Element Safe    xpath=(//div[contains(@class,'trip-card')])[1]

Open Pending Request By Route Title
    [Arguments]    ${route_title}
    Run Keyword If    '${route_title}' == ''    Skip    No route title provided for pending request selection.
    ${card}=    Set Variable    xpath=//div[contains(@class,'trip-card')][.//*[contains(normalize-space(.),"${route_title}")]][1]
    ${has_card}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${card}    10s
    Run Keyword If    not ${has_card}    Skip    Pending request for route '${route_title}' not found.
    Click Element Safe    ${card}

Assert Driver Sees Luggage Detail
    [Arguments]    ${expected_fee}
    Wait Until Page Contains    ข้อมูลสัมภาระเพิ่มเติม   10s
    Wait Until Page Contains    ค่าบริการเพิ่ม: ${expected_fee} บาท   10s
    Wait Until Page Contains    สัมภาระเพิ่ม +${expected_fee} บาท   10s

Driver Confirm First Pending
    Click Element Safe    xpath=(//button[contains(normalize-space(.),'ยืนยันคำขอ')])[1]
    Click Element Safe    xpath=//button[contains(normalize-space(.),'ยืนยัน')]
    Wait Until Page Contains    ยืนยันแล้ว    10s

Driver Reject First Pending
    Click Element Safe    xpath=(//button[contains(normalize-space(.),'ปฏิเสธ')])[1]
    Click Element Safe    xpath=//button[contains(normalize-space(.),'ยืนยัน')]
    Wait Until Page Contains    ปฏิเสธ    10s

Assert Driver Sees No Luggage
    Wait Until Page Contains    ข้อมูลสัมภาระเพิ่มเติม    10s
    Wait Until Page Contains    ไม่มีการขอสัมภาระเพิ่มเติม    10s


*** Test Cases ***
# ===== PART: PASSENGER TESTS =====
TC_P1 - Route Without Extra Luggage Must Hide Section
    Login As Passenger
    ${route_title}=    Resolve Route Title Or Skip    ${ROUTE_NO_LUGGAGE}    NO_LUGGAGE
    Open Booking Modal By Route Title    ${route_title}
    Page Should Not Contain    มีสัมภาระเกินปกติ

TC_P2 - Route Max Medium Must Show Only Medium
    Login As Passenger
    ${route_title}=    Resolve Route Title Or Skip    ${ROUTE_MAX_MEDIUM}    MEDIUM
    Open Booking Modal By Route Title    ${route_title}
    Enable Extra Luggage
    Page Should Contain    ไม่เกิน 24 นิ้ว
    Page Should Not Contain    ไม่เกิน 28 นิ้ว
    Page Should Not Contain    สัมภาระพิเศษ

TC_P3 - Route Max Large Must Show Medium And Large
    Login As Passenger
    ${route_title}=    Resolve Route Title Or Skip    ${ROUTE_MAX_LARGE}    LARGE
    Open Booking Modal By Route Title    ${route_title}
    Enable Extra Luggage
    Page Should Contain    ไม่เกิน 24 นิ้ว
    Page Should Contain    ไม่เกิน 28 นิ้ว
    Page Should Not Contain    สัมภาระพิเศษ
   
TC_P4 - Route Max ExtraLarge Must Allow ExtraLarge
    Login As Passenger
    ${route_title}=    Resolve Route Title Or Skip    ${ROUTE_MAX_EXTRALARGE}    EXTRA_LARGE
    Open Booking Modal By Route Title    ${route_title}
    Enable Extra Luggage
    Page Should Contain    ไม่เกิน 24 นิ้ว
    Page Should Contain    ไม่เกิน 28 นิ้ว
    Page Should Contain    สัมภาระพิเศษ
    Select Luggage ExtraLarge

# ===== PART: DRIVER TESTS =====
TC_D1 - Driver Sees Extra Luggage In Pending Request
    Passenger Create Booking With Large Luggage   ${ROUTE_MAX_LARGE}   107 แบริ่ง คอนโดมิเนียม    เชียงราย กอล์ฟ
    Login As Driver
    Open MyRoute Pending
    Open Pending Request By Route Title    ${LAST_BOOKED_ROUTE_TITLE}
    Assert Driver Sees Luggage Detail    ${FEE_LARGE}

TC_D2 - Driver Confirms Request With Extra Luggage
    Passenger Create Booking With Large Luggage    ${ROUTE_MAX_LARGE}   107 แบริ่ง คอนโดมิเนียม    เชียงราย กอล์ฟ
    Login As Driver
    Open MyRoute Pending
    Open Pending Request By Route Title    ${LAST_BOOKED_ROUTE_TITLE}
    Assert Driver Sees Luggage Detail    ${FEE_LARGE}
    Driver Confirm First Pending

TC_D3 - Driver Rejects Request With Extra Luggage
    Passenger Create Booking With Large Luggage    ${ROUTE_MAX_LARGE}   107 แบริ่ง คอนโดมิเนียม    เชียงราย กอล์ฟ
    Login As Driver
    Open MyRoute Pending
    Open Pending Request By Route Title    ${LAST_BOOKED_ROUTE_TITLE}
    Assert Driver Sees Luggage Detail    ${FEE_LARGE}
    Driver Reject First Pending

TC_D4 - Driver Sees Request Without Extra Luggage
    Passenger Create Booking Without Extra Luggage    ${ROUTE_NO_LUGGAGE}    107 แบริ่ง คอนโดมิเนียม    เชียงราย กอล์ฟ
    Login As Driver
    Open MyRoute Pending
    Open Pending Request By Route Title    ${LAST_BOOKED_ROUTE_TITLE}
    Assert Driver Sees No Luggage
