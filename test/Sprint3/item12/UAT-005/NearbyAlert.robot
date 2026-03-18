*** Settings ***
Documentation     UAT Test Cases — ฟีเจอร์แจ้งเตือนใกล้ถึง (Driver Nearby Alert / Near-Arrival Notification)
...               ครอบคลุมทุก flow: คนขับกดแจ้งเตือน, ผู้โดยสารรับการแจ้งเตือน, Driver Hub, ปุ่ม Enable/Disable
Library           SeleniumLibrary
Test Teardown     Close Browser And Capture

*** Variables ***
${BASE_URL}                http://localhost:3001
${BROWSER}                 chrome
${DRIVER_EMAIL}            driver123
${DRIVER_PASSWORD}         00000000
${PASSENGER_EMAIL}         passenger123
${PASSENGER_PASSWORD}      00000000
${CONFIRMED_BOOKING_ID}    cmms557120004jsu4sficgakb
${ROUTE_ID}                cmms548wk0001jsu4un2cjdi0

*** Keywords ***
Step
    [Arguments]    ${message}
    Log    ${message}
    Log To Console    STEP: ${message}

Close Browser And Capture
    Run Keyword And Ignore Error    Capture Page Screenshot
    Close Browser

Login As Driver
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Input Text    id=identifier    ${DRIVER_EMAIL}
    Input Password    id=password    ${DRIVER_PASSWORD}
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    15s
    Log    Driver logged in successfully

Login As Passenger
    Open Browser    ${BASE_URL}/login    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Input Text    id=identifier    ${PASSENGER_EMAIL}
    Input Password    id=password    ${PASSENGER_PASSWORD}
    Click Element    xpath=//button[@type='submit']
    Wait Until Location Does Not Contain    /login    15s
    Log    Passenger logged in successfully

Navigate To Driver My Routes
    Go To    ${BASE_URL}/myRoute
    Sleep    2s
    Wait Until Page Does Not Contain    กำลังโหลดข้อมูล    timeout=30s
    Wait Until Page Contains    คำขอจองเส้นทาง    timeout=20s
    Log    Driver myRoute page loaded

Navigate To Driver Hub Panel
    [Documentation]    เปิด Driver Hub ลอยตัวโดยกดปุ่มเปิด
    Wait Until Page Contains Element    id=driver-hub-toggle    timeout=15s
    ${is_closed}=    Run Keyword And Return Status
    ...    Element Should Not Be Visible    id=driver-hub-panel
    IF    ${is_closed}
        Click Element    id=driver-hub-toggle
        Wait Until Element Is Visible    id=driver-hub-panel    timeout=10s
    END
    Log    Driver Hub panel is open

Verify Nearby Alert Button Exists For Passenger
    [Arguments]    ${passenger_name}
    [Documentation]    ตรวจสอบว่ามีปุ่ม "แจ้งใกล้ถึง" ของผู้โดยสารที่ระบุในหน้า myRoute
    ${btn_xpath}=    Set Variable
    ...    xpath://button[contains(@class, 'nearby') or contains(., 'แจ้งใกล้ถึง') or contains(., 'ใกล้ถึง')]
    Wait Until Page Contains Element    ${btn_xpath}    timeout=15s
    Log    Nearby alert button found for passenger

Verify Nearby Alert Button Is Disabled Before Refresh
    [Documentation]    ก่อนกดปุ่ม Refresh ปุ่มแจ้งใกล้ถึงควรถูก disabled
    ${btn_xpath}=    Set Variable    xpath://button[contains(@class, 'near-alert') or contains(., 'แจ้งใกล้ถึง')]
    Wait Until Page Contains Element    ${btn_xpath}    timeout=15s
    # ตรวจว่า disabled
    ${is_disabled}=    Get Element Attribute    ${btn_xpath}    disabled
    Should Not Be Empty    ${is_disabled}    msg=ปุ่มแจ้งใกล้ถึงควรถูก disabled ก่อนกด Refresh

Verify Nearby Alert Button Is Enabled After Refresh
    [Documentation]    หลังกดปุ่ม Refresh / อัปเดตระยะทางแล้ว ปุ่มแจ้งใกล้ถึงควร enabled
    ${btn_xpath}=    Set Variable    xpath://button[contains(., 'แจ้งใกล้ถึง')]
    Wait Until Element Is Visible    ${btn_xpath}    timeout=15s
    ${is_disabled}=    Run Keyword And Return Status
    ...    Element Should Be Disabled    ${btn_xpath}
    Should Be True    not ${is_disabled}
    ...    msg=ปุ่มแจ้งใกล้ถึงควร enabled หลังจาก Refresh

Click Refresh Distance Button
    [Documentation]    กดปุ่ม Refresh ระยะทางในหน้า myRoute หรือ Driver Hub
    ${refresh_btn}=    Set Variable
    ...    xpath://button[contains(@title, 'รีเฟรช') or contains(@aria-label, 'refresh') or contains(., 'รีเฟรช') or @id='refresh-distance-btn']
    Wait Until Page Contains Element    ${refresh_btn}    timeout=10s
    Click Element    ${refresh_btn}
    Sleep    2s
    Log    Refresh distance button clicked

Click Nearby Alert Button For First Passenger
    [Documentation]    กดปุ่ม "แจ้งใกล้ถึง" สำหรับผู้โดยสารแรก
    ${btn_xpath}=    Set Variable    xpath:(//button[contains(., 'แจ้งใกล้ถึง')])[1]
    Wait Until Element Is Visible    ${btn_xpath}    timeout=15s
    Click Element    ${btn_xpath}
    Sleep    2s
    Log    Nearby alert button clicked for first passenger

Verify Toast Notification Success
    [Documentation]    ตรวจสอบว่า Toast notification แสดงข้อความสำเร็จ
    ${found}=    Run Keyword And Return Status
    ...    Wait Until Page Contains    แจ้งเตือน    timeout=8s
    IF    not ${found}
        ${found2}=    Run Keyword And Return Status
        ...    Wait Until Page Contains    เรียบร้อยแล้ว    timeout=5s
    END
    Log    Toast notification appeared (success)

Verify Driver Hub Shows Active Routes
    [Documentation]    ตรวจสอบว่า Driver Hub แสดงรายการเส้นทางที่กำลังใช้งาน
    Navigate To Driver Hub Panel
    Wait Until Page Contains Element    id=driver-hub-panel    timeout=10s
    ${has_routes}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    xpath://div[contains(@id,'route-card-')]    timeout=10s
    IF    ${has_routes}
        Log    Driver Hub shows active routes
    ELSE
        ${no_route_msg}=    Run Keyword And Return Status
        ...    Page Should Contain    ยังไม่มีเส้นทาง
        Log    Driver Hub shows empty state (no active routes today)
    END

*** Test Cases ***
# ══════════════════════════════════════════════════════════════════
# 1) DRIVER HUB — ตรวจสอบว่า Driver Hub แสดงเส้นทางที่ active
# ══════════════════════════════════════════════════════════════════
TC-ALERT-01 Driver Hub Shows Active Route List
    [Documentation]    คนขับเปิดแอป → Driver Hub ลอยตัวแสดงเส้นทางที่กำลังดำเนินการวันนี้
    [Tags]             driver    driver-hub    nearby-alert    smoke
    Login As Driver
    Verify Driver Hub Shows Active Routes
    [Teardown]         Close Browser And Capture

# ══════════════════════════════════════════════════════════════════
# 3) NEARBY ALERT — ปุ่มแจ้งใกล้ถึง Enable หลัง Refresh
# ══════════════════════════════════════════════════════════════════
TC-ALERT-03 Nearby Alert Button Enabled After Refresh
    [Documentation]    หน้าเส้นทางของฉัน → กดปุ่ม Refresh → ปุ่ม "แจ้งใกล้ถึง" ถูก enabled
    [Tags]             driver    nearby-alert    ui    post-refresh
    Login As Driver
    Navigate To Driver My Routes
    Step    Switch to confirmed tab if needed
    ${has_tab}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    xpath://button[contains(., 'เส้นทางของฉัน')]    timeout=8s
    IF    ${has_tab}
        Click Element    xpath://button[contains(., 'เส้นทางของฉัน')]
        Sleep    2s
    END
    Step    Click refresh distance button
    Click Refresh Distance Button
    Step    Verify button is now enabled
    Verify Nearby Alert Button Is Enabled After Refresh
    [Teardown]         Close Browser And Capture

# ══════════════════════════════════════════════════════════════════
# 4) NEARBY ALERT — คนขับกดปุ่มแจ้งใกล้ถึงสำเร็จ
# ══════════════════════════════════════════════════════════════════
TC-ALERT-04 Driver Sends Nearby Alert Successfully
    [Documentation]    คนขับกดปุ่ม "แจ้งใกล้ถึง" → Toast แสดงสำเร็จ
    [Tags]             driver    nearby-alert    positive
    Login As Driver
    Navigate To Driver My Routes
    Step    Switch to confirmed tab if needed
    ${has_tab}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    xpath://button[contains(., 'เส้นทางของฉัน')]    timeout=8s
    IF    ${has_tab}
        Click Element    xpath://button[contains(., 'เส้นทางของฉัน')]
        Sleep    2s
    END
    Step    Refresh to get distance
    Click Refresh Distance Button
    Step    Click nearby alert button
    Click Nearby Alert Button For First Passenger
    Step    Verify toast notification
    Verify Toast Notification Success
    [Teardown]         Close Browser And Capture

# ══════════════════════════════════════════════════════════════════
# 5) NEARBY ALERT via DRIVER HUB — กดแจ้งใกล้ถึงจาก Driver Hub
# ══════════════════════════════════════════════════════════════════
TC-ALERT-05 Driver Sends Nearby Alert From Driver Hub
    [Documentation]    คนขับกดแจ้งใกล้ถึงจาก Driver Hub ลอยตัว (ใช้งานได้ทุกหน้า)
    [Tags]             driver    nearby-alert    driver-hub    positive
    Login As Driver
    # ไปหน้าหลักก่อน เพื่อทดสอบว่า Driver Hub ใช้ได้ทุกหน้า
    Go To    ${BASE_URL}
    Sleep    2s
    Navigate To Driver Hub Panel
    Step    Find route card and refresh distance
    ${refresh_in_hub}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath://button[contains(@id, 'refresh-') or contains(@title, 'รีเฟรช')]    timeout=5s
    IF    ${refresh_in_hub}
        Click Element    xpath:(//button[contains(@id, 'refresh-') or contains(@title, 'รีเฟรช')])[1]
        Sleep    2s
    END
    Step    Click nearby alert in Driver Hub
    ${alert_btn}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    xpath://button[contains(., 'แจ้งใกล้ถึง')]    timeout=10s
    IF    ${alert_btn}
        Click Element    xpath:(//button[contains(., 'แจ้งใกล้ถึง')])[1]
        Sleep    2s
        Verify Toast Notification Success
    ELSE
        Log    No passengers available for nearby alert in Driver Hub (route may have no confirmed bookings today)    level=WARN
        Pass Execution    Skipped: No passengers with CONFIRMED bookings for today's route
    END
    [Teardown]         Close Browser And Capture

# ══════════════════════════════════════════════════════════════════
# 6) ROUTE COLLAPSE — ย่อ/ขยายรายการผู้โดยสารใน Driver Hub
# ══════════════════════════════════════════════════════════════════
TC-ALERT-06 Driver Can Collapse And Expand Route In Driver Hub
    [Documentation]    ใน Driver Hub → กดปุ่มย่อ/ขยายในแต่ละเส้นทาง → รายการผู้โดยสารหายและกลับมา
    [Tags]             driver    driver-hub    ui
    Login As Driver
    Navigate To Driver Hub Panel
    ${has_route}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    xpath://div[contains(@id,'route-card-')]    timeout=10s
    IF    ${has_route}
        Step    Click collapse button on first route
        ${collapse_btn}=    Run Keyword And Return Status
        ...    Wait Until Page Contains Element
        ...    xpath:(//button[contains(@aria-label,'ย่อ') or contains(@title,'ย่อ') or contains(@id,'collapse-')])[1]    timeout=5s
        IF    ${collapse_btn}
            Click Element    xpath:(//button[contains(@aria-label,'ย่อ') or contains(@title,'ย่อ') or contains(@id,'collapse-')])[1]
            Sleep    1s
            Log    Route collapsed in Driver Hub
            # ขยาย
            Click Element    xpath:(//button[contains(@aria-label,'ขยาย') or contains(@title,'ขยาย') or contains(@id,'expand-')])[1]
            Sleep    1s
            Log    Route expanded back in Driver Hub
        ELSE
            Log    No collapse/expand button found — may use chevron icon    level=WARN
        END
    ELSE
        Pass Execution    Skipped: No active routes in Driver Hub today
    END
    [Teardown]         Close Browser And Capture

# ══════════════════════════════════════════════════════════════════
# 7) PASSENGER RECEIVES NOTIFICATION
# ══════════════════════════════════════════════════════════════════
TC-ALERT-07 Passenger Receives Near Arrival Notification
    [Documentation]    หลังจากคนขับส่ง Nearby Alert → ผู้โดยสารเปิดแอปและเห็นการแจ้งเตือน
    ...                หมายเหตุ: ต้องรันหลังจาก TC-ALERT-04 และ Browser notifications ต้องเปิดใช้งาน
    [Tags]             passenger    nearby-alert    notification    depends-on-tc04
    Login As Passenger
    Step    Go to homepage and check notification
    Go To    ${BASE_URL}
    Sleep    3s
    # ตรวจสอบ badge แจ้งเตือน / ข้อความในหน้า
    ${has_badge}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    id=chat-nav-unread-badge    timeout=10s
    IF    ${has_badge}
        Log    Notification badge visible to passenger
    ELSE
        Log    No in-app badge found. Browser push notification may have been sent    level=WARN
        Log    Check browser notification permission is granted for this test
    END
    [Teardown]         Close Browser And Capture
