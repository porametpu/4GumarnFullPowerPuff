*** Settings ***
Library    SeleniumLibrary
Test Teardown    Close Browser And Capture
Suite Teardown    Print Report Paths

*** Variables ***
${BASE_URL}          http://localhost:3001
${BROWSER}           chrome
${LOGIN_EMAIL}       delete2@test.com
${LOGIN_PASSWORD}    00000000
${WRONG_EMAIL}       not-match@example.com
${DELETE_EMAIL_INPUT}    xpath=//input[@placeholder='กรอกอีเมลของคุณเพื่อยืนยัน']
${DELETE_BUTTON}    xpath=//button[normalize-space()='ลบบัญชีถาวร']
${LOGIN_EMAIL_BOOKING}       delete3@test.com
${LOGIN_PASSWORD_BOOKING}    00000000

*** Keywords ***
Step
    [Arguments]    ${message}
    Log    ${message}
    Log To Console    STEP: ${message}

Close Browser And Capture
    Run Keyword And Ignore Error    Capture Page Screenshot
    Close Browser

Print Report Paths
    Log To Console    \n===== Robot Report =====
    Log To Console    Report: ${OUTPUT DIR}${/}report.html
    Log To Console    Log: ${OUTPUT DIR}${/}log.html
    Log To Console    Output: ${OUTPUT DIR}${/}output.xml

Login And Open Delete Account Page
    Step    Open login page
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Step    Fill login form
    Wait Until Element Is Visible    id=identifier
    Input Text    id=identifier    ${LOGIN_EMAIL}
    Input Password    id=password    ${LOGIN_PASSWORD}
    Step    Submit login
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    10s
    Step    Open delete account page
    Go To    ${BASE_URL}/profile/delete-account
    Wait Until Location Contains   /profile/delete-account   10s
    Wait Until Element Is Visible    ${DELETE_EMAIL_INPUT}   15s
   

Submit Delete Account Email
    [Arguments]    ${email}
   ${url}=    Get Location
   Log To Console    URL NOW: ${url}
    Wait Until Element Is Visible    ${DELETE_EMAIL_INPUT}    15s
    Clear Element Text    ${DELETE_EMAIL_INPUT}
    Input Text    ${DELETE_EMAIL_INPUT}    ${email}
    Click Element    ${DELETE_BUTTON}
    Handle Alert    accept

Verify Delete Button Is Disabled
    [Documentation]    ตรวจสอบว่าปุ่มลบบัญชีถูก disable เนื่องจากมีการจองที่ active
    Wait Until Page Contains Element    ${DELETE_BUTTON}    timeout=15s
    ${is_disabled}=    Get Element Attribute    ${DELETE_BUTTON}    disabled
    Should Not Be Empty    ${is_disabled}
    ...    msg=ปุ่มลบบัญชีควรถูก disabled เมื่อมีการจองที่ active

Verify Delete Button Is Enabled
    [Documentation]    ตรวจสอบว่าปุ่มลบบัญชีสามารถกดได้เมื่อไม่มีการจองที่ active
    Wait Until Element Is Visible    ${DELETE_BUTTON}    timeout=15s
    ${is_disabled}=    Run Keyword And Return Status
    ...    Element Should Be Disabled    ${DELETE_BUTTON}
    Should Be True    not ${is_disabled}
    ...    msg=ปุ่มลบบัญชีควร enabled เมื่อไม่มีการจองที่ active

Verify Warning Message About Active Bookings
    [Documentation]    ตรวจสอบว่าหน้าแสดงข้อความแจ้งเตือนว่าไม่สามารถลบได้เนื่องจากมีการจองที่ active
    Wait Until Page Contains    การจอง    timeout=15s
    ${has_warning}=    Run Keyword And Return Status
    ...    Page Should Contain    ไม่สามารถลบบัญชีได้
    ${has_warning2}=    Run Keyword And Return Status
    ...    Page Should Contain    มีการจองที่ยังดำเนินการ
    ${has_any}=    Evaluate    ${has_warning} or ${has_warning2}
    IF    ${has_any}
        Log    Warning message about active bookings is displayed
    ELSE
        Log    WARNING: No specific warning message found, checking disabled button state    level=WARN
        Verify Delete Button Is Disabled
    END

Login And Open Delete Account Page with Booking
    [Arguments]    ${email}    ${password}
    Step    Open login page
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Step    Fill login form
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Input Text    id=identifier    ${LOGIN_EMAIL_BOOKING}
    Input Password    id=password    ${LOGIN_PASSWORD_BOOKING}
    Step    Submit login
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    10s
    Step    Navigate to delete account page
    Go To    ${BASE_URL}/profile/delete-account
    Wait Until Location Contains    /profile/delete-account    10s


*** Test Cases ***
TC1 - Delete Account With Wrong Email
    Login And Open Delete Account Page
    Submit Delete Account Email    ${WRONG_EMAIL}
    Step    Verify error message for unmatched email
    Wait Until Page Contains    อีเมลไม่ตรงกับบัญชีนี้

TC2 - Delete Account With Correct Email
    [Documentation]    ใช้ test account เท่านั้น เพราะเคสนี้จะถูกทำเครื่องหมายลบบัญชีจริง
    Login And Open Delete Account Page
    Submit Delete Account Email    ${LOGIN_EMAIL}
    Step    Verify success message
    Wait Until Page Contains    คำขอการลบบัญชีสำเร็จ

TC3 - Test After Deletion
    [Documentation]    ต้องใช้ account ที่ถูกส่งคำขอลบบัญชีแล้ว
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier
    Input Text    id=identifier    ${LOGIN_EMAIL}
    Input Password    id=password    ${LOGIN_PASSWORD}
    Click Element    xpath=//button[@type='submit']
    Wait Until Page Contains    เข้าสู่ระบบไม่สำเร็จ    10s
    Location Should Contain    /login

TC4 - User With Active Booking Cannot Delete Account
    [Documentation]    ผู้ใช้ที่มีการจอง CONFIRMED อยู่ → ปุ่มลบบัญชีถูก disabled
    ...                หรือหน้าแสดงข้อความแจ้งว่าไม่สามารถลบได้
    [Tags]             delete-account    active-booking    negative
    Login And Open Delete Account Page with Booking    ${LOGIN_EMAIL}    ${LOGIN_PASSWORD}
    Step    Verify delete button is disabled due to active booking
    Verify Delete Button Is Disabled


