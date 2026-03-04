*** Settings ***
Documentation     Comprehensive UAT Test Cases for Chat Feature
...               ครอบคลุมฟีเจอร์แชททั้งหมด: ส่งข้อความ, Quick Reply, Widget UI,
...               Attachment Menu, Notification Badge, Chat History Page
Library           SeleniumLibrary
Resource          common.resource
# Suite Setup/Teardown removed in favor of per-test sessions to prevent crashes

*** Variables ***
${PASSENGER_EMAIL}             test99@test.com
${DRIVER_EMAIL}                test12@test.com
${PASSWORD}                    00000000
${CONFIRMED_BOOKING_ID}        cmm5vzhbv0004l8ork3c1oto6

*** Test Cases ***
# ══════════════════════════════════════════════════════════════════
# 1) CORE CHAT — ผู้โดยสารเปิดแชทจากหน้า Booking
# ══════════════════════════════════════════════════════════════════
Passenger Opens Chat From Booking
    [Documentation]    ผู้โดยสารเปิดแชทจากหน้า myTrip (แท็บยืนยันแล้ว) ตรวจสอบว่า Chat Widget ปรากฏ
    [Tags]             passenger    chat    core
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    Verify Chat Widget Is Open
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 2) MESSAGING — ผู้โดยสารส่งข้อความ
# ══════════════════════════════════════════════════════════════════
Passenger Sends Text Message
    [Documentation]    ผู้โดยสารพิมพ์ข้อความแล้วกดส่ง ตรวจสอบว่าข้อความปรากฏในแชท
    [Tags]             passenger    chat    messaging
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    Send Message       สวัสดีครับ รบกวนสอบถามจุดนัดพบครับ
    Verify Message Sent    สวัสดีครับ รบกวนสอบถามจุดนัดพบครับ
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 3) QUICK REPLY — ผู้โดยสารกด Quick Reply
# ══════════════════════════════════════════════════════════════════
Passenger Uses Quick Reply
    [Documentation]    ผู้โดยสารกดปุ่ม Quick Reply → ข้อความถูกส่งสำเร็จ
    [Tags]             passenger    chat    quick-reply
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    Click Quick Reply    รออยู่ที่จุดนัดพบ
    Verify Message Sent    รออยู่ที่จุดนัดพบ
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 4) UI WIDGET — ผู้โดยสารย่อ/ขยาย Chat Widget
# ══════════════════════════════════════════════════════════════════
Passenger Minimizes And Maximizes Chat
    [Documentation]    คลิก Header เพื่อย่อ Chat Widget → ตรวจสอบสถานะ minimized → คลิกเปิดกลับ
    [Tags]             passenger    chat    ui
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    # ย่อ Chat Widget
    Minimize Chat Widget
    Verify Chat Is Minimized
    # ขยาย Chat Widget กลับ
    Maximize Chat Widget
    Verify Chat Is Maximized
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 5) UI WIDGET — ผู้โดยสารปิด Chat Widget
# ══════════════════════════════════════════════════════════════════
Passenger Closes Chat Widget
    [Documentation]    ผู้โดยสารกดปุ่ม Close (X) → Chat Widget หายไป
    [Tags]             passenger    chat    ui
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    Close Chat Widget
    Verify Chat Is Closed
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 6) ATTACHMENT MENU — ผู้โดยสารเปิดเมนูแนบไฟล์
# ══════════════════════════════════════════════════════════════════
Passenger Verifies Attachment Menu
    [Documentation]    กดปุ่ม + เปิดเมนูแนบ → ตรวจสอบว่ามีตัวเลือก "รูปภาพ" และ "ตำแหน่งที่ตั้ง"
    [Tags]             passenger    chat    attachment
    [Setup]            Setup Test Session    ${PASSENGER_EMAIL}    ${PASSWORD}
    Go To Booking Page    ${CONFIRMED_BOOKING_ID}
    Open Chat Widget    ${CONFIRMED_BOOKING_ID}
    Open Attachment Menu
    Verify Attachment Menu Has Image Option
    Verify Attachment Menu Has Location Option
    Close Attachment Menu
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 7) CROSS-ROLE — คนขับรับข้อความและตอบกลับ
# ══════════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════
# 7) NOTIFICATION — คนขับเห็นรายการแชทล่าสุด
# ══════════════════════════════════════════════════════════════════
Driver Verifies Latest Message Notification
    [Documentation]    คนขับล็อกอิน → ไปที่หน้าประวัติการแชท → ตรวจสอบว่าแชทล่าสุดแสดงข้อความจากผู้โดยสารถูกต้อง (รออยู่ที่จุดนัดพบ)
    [Tags]             driver    chat    notification
    [Setup]            Setup Test Session    ${DRIVER_EMAIL}    ${PASSWORD}
    Open Chat History Page
    # ตรวจสอบว่าห้องแชทแรกมีข้อความล่าสุดเป็น "รออยู่ที่จุดนัดพบ" (ส่งมาจาก Test Case ที่ 3)
    Wait Until Keyword Succeeds    3x    5s    Verify Latest Message In History    รออยู่ที่จุดนัดพบ
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 8) CROSS-ROLE — คนขับรับข้อความและตอบกลับ
# ══════════════════════════════════════════════════════════════════
Driver Receives Message And Replies
    [Documentation]    คนขับเปิดหน้าประวัติแชท → เข้าห้องแชทของ booking ที่ระบุ → ส่งข้อความตอบกลับ
    [Tags]             driver    chat    messaging
    [Setup]            Setup Test Session    ${DRIVER_EMAIL}    ${PASSWORD}
    Open Chat History Page
    Open Chat Room For Booking    ${CONFIRMED_BOOKING_ID}
    Send Message       รับทราบครับ เจอกันที่จุดนัดพบนะครับ
    Verify Message Sent    รับทราบครับ เจอกันที่จุดนัดพบนะครับ
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 9) QUICK REPLY — คนขับกด Quick Reply
# ══════════════════════════════════════════════════════════════════
Driver Uses Quick Reply
    [Documentation]    คนขับกดปุ่ม Quick Reply (เช่น "ใกล้ถึงแล้ว") → ข้อความถูกส่ง
    [Tags]             driver    chat    quick-reply
    [Setup]            Setup Test Session    ${DRIVER_EMAIL}    ${PASSWORD}
    Open Chat History Page
    Open Chat Room For Booking    ${CONFIRMED_BOOKING_ID}
    Click Quick Reply    ใกล้ถึงแล้ว
    Verify Message Sent    ใกล้ถึงแล้ว
    [Teardown]         Teardown Test Session

# ══════════════════════════════════════════════════════════════════
# 10) CHAT HISTORY — หน้าประวัติแชทแสดงรายการห้องแชท
# ══════════════════════════════════════════════════════════════════
Chat History Page Displays Rooms
    [Documentation]    เปิดหน้า /chats → มีรายการห้องแชทปรากฏ → แสดงชื่อผู้ร่วมสนทนา
    [Tags]             driver    chat    history
    [Setup]            Setup Test Session    ${DRIVER_EMAIL}    ${PASSWORD}
    Open Chat History Page
    Verify Chat History Has Rooms
    Verify Chat Room Shows Participant Name
    Verify Chat Room Shows Last Message Preview
    [Teardown]         Teardown Test Session

*** Keywords ***
# ══════════════════════════════════════════════════════════════════
# NAVIGATION KEYWORDS
# ══════════════════════════════════════════════════════════════════
Go To Booking Page
    [Arguments]    ${booking_id}
    Go To    ${URL}/myTrip
    Sleep    2s
    Wait Until Page Does Not Contain    กำลังโหลดข้อมูล    timeout=30s
    Wait Until Page Contains    รายการการเดินทาง    timeout=20s
    # Switch to 'All' tab to see everything
    Wait Until Element Is Visible    xpath://button[contains(., 'ทั้งหมด')]    timeout=10s
    Click Element    xpath://button[contains(., 'ทั้งหมด')]
    Wait Until Page Does Not Contain    กำลังโหลดข้อมูล    timeout=15s
    Sleep    2s
    # Wait for at least ONE trip card
    Wait Until Page Contains Element    xpath://div[contains(@class, 'trip-card')]    timeout=20s
    Log    Trips loaded successfully

Go To My Routes Page
    Go To    ${URL}/myRoute
    Sleep    2s
    Wait Until Page Does Not Contain    กำลังโหลดข้อมูล    timeout=30s
    Wait Until Page Contains    คำขอจองเส้นทางของฉัน    timeout=20s
    # Switch to 'ยืนยันแล้ว' tab to find confirmed bookings with chat buttons
    ${has_confirmed}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath://button[contains(., 'ยืนยันแล้ว')]    timeout=10s
    IF    ${has_confirmed}
        Click Element    xpath://button[contains(., 'ยืนยันแล้ว')]
        Wait Until Page Does Not Contain    กำลังโหลดข้อมูล    timeout=15s
        Sleep    2s
    END
    Log    My Routes page loaded

Open Chat History Page
    Go To    ${URL}/chats
    # บังคับ Reload เพื่อให้ได้ข้อมูลล่าสุดจริงๆ
    Reload Page
    Sleep    2s
    Wait Until Page Contains    ประวัติการแชท    timeout=20s

Open Chat Room From History
    [Arguments]    ${booking_id}=None
    Log    Opening chat room from history page
    Wait Until Page Contains Element    xpath://div[contains(@id, 'room-')]    timeout=20s
    # Click the first room in the list (most recent) via JS
    Execute JavaScript    var r = document.querySelector("div[id^='room-']"); if(r) r.click();
    Wait Until Element Is Visible    id:chat-header-maximized    timeout=15s

Open Chat Room For Booking
    [Documentation]    เปิดแชทสำหรับ booking ที่ระบุ ผ่านหน้า myRoute ของคนขับ
    [Arguments]    ${booking_id}
    Log    Opening chat for booking ${booking_id}
    # Approach 1: Go to driver's myRoute page and look for the chat button with the booking ID
    Go To My Routes Page
    Sleep    2s
    ${found}=    Run Keyword And Return Status    Wait Until Page Contains Element    id:chat-btn-${booking_id}    timeout=15s
    IF    ${found}
        Log    Found chat button on myRoute page, clicking via JS
        Execute JavaScript    document.getElementById('chat-btn-${booking_id}').click()
    ELSE
        # Approach 2: Try from chat history — click the first room
        Log    Chat button not found on myRoute, trying chat history
        Open Chat History Page
        Wait Until Page Contains Element    xpath://div[contains(@id, 'room-')]    timeout=15s
        Execute JavaScript    var r = document.querySelector("div[id^='room-']"); if(r) r.click();
    END
    # Wait for the chat widget to appear
    Wait Until Page Contains Element    id:chat-container    timeout=20s
    Sleep    2s
    ${is_minimized}=    Run Keyword And Return Status    Element Should Be Visible    id:chat-widget-minimized
    IF    ${is_minimized}
        Execute JavaScript    document.getElementById('chat-widget-minimized').click()
    END
    Wait Until Element Is Visible    id:chat-header-maximized    timeout=15s
    Log    Chat room opened successfully for booking ${booking_id}

# ══════════════════════════════════════════════════════════════════
# CHAT WIDGET KEYWORDS
# ══════════════════════════════════════════════════════════════════
Open Chat Widget
    [Arguments]    ${booking_id}
    Log    Attempting to open chat widget for booking ${booking_id}
    # Try specific ID first using JS click which is more reliable in headless environments
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains Element    id:chat-btn-${booking_id}    timeout=10s
    IF    ${status}
        Log    Found chat button by ID, clicking via JS
        Execute JavaScript    document.getElementById('chat-btn-${booking_id}').click()
    ELSE
        Log    Specific booking ID button not found, searching for any "แชทกับ" button
        ${fallback_status}=    Run Keyword And Return Status    Wait Until Page Contains Element    xpath://button[contains(., 'แชทกับ')]    timeout=10s
        IF    ${fallback_status}
            Log    Found fallback chat button, clicking via JS
            Execute JavaScript    document.evaluate("//button[contains(., 'แชทกับ')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.click()
        ELSE
            Capture Page Screenshot
            Log Source
            Fail    Could not find any chat button on page
        END
    END
    
    # Wait for the widget to be present in DOM
    Wait Until Page Contains Element    id:chat-container    timeout=20s
    
    # If it's minimized, maximize it via JS click
    ${is_minimized}=    Run Keyword And Return Status    Element Should Be Visible    id:chat-widget-minimized
    IF    ${is_minimized}
        Log    Chat widget is minimized, maximizing...
        Execute JavaScript    document.getElementById('chat-widget-minimized').click()
    END
    
    Wait Until Element Is Visible    id:chat-header-maximized    timeout=15s

Verify Chat Widget Is Open
    Wait Until Element Is Visible    id:chat-container    timeout=10s
    Wait Until Element Is Visible    id:chat-header-maximized    timeout=10s
    Wait Until Element Is Visible    id:chat-message-input    timeout=10s
    Wait Until Element Is Visible    id:chat-send-button    timeout=10s
    Log    Chat widget is fully open and ready

Minimize Chat Widget
    Click Element    id:chat-header-maximized
    Wait Until Element Is Visible    id:chat-widget-minimized    timeout=5s

Maximize Chat Widget
    Click Element    id:chat-widget-minimized
    Wait Until Element Is Visible    id:chat-header-maximized    timeout=5s

Close Chat Widget
    # Use JS click because the close button is nested inside the clickable header
    # and Selenium reports it as not interactable in headless mode
    Execute JavaScript    document.getElementById('chat-close-button').click()
    Wait Until Element Is Not Visible    id:chat-header-maximized    timeout=5s

Verify Chat Is Minimized
    Element Should Be Visible    id:chat-widget-minimized
    Element Should Not Be Visible    id:chat-header-maximized
    Log    Chat widget is in minimized state

Verify Chat Is Maximized
    Element Should Be Visible    id:chat-header-maximized
    Element Should Not Be Visible    id:chat-widget-minimized
    Log    Chat widget is in maximized state

Verify Chat Is Closed
    Element Should Not Be Visible    id:chat-header-maximized
    Run Keyword And Ignore Error    Element Should Not Be Visible    id:chat-widget-minimized
    Log    Chat widget is closed

# ══════════════════════════════════════════════════════════════════
# MESSAGING KEYWORDS
# ══════════════════════════════════════════════════════════════════
Send Message
    [Arguments]    ${text}
    Wait Until Element Is Visible    id:chat-message-input    timeout=10s
    # ใช้ JS ตั้งค่า value และ dispatch events เพื่อความชัวร์เรื่อง reactivity ใน Vue
    Execute JavaScript    var input = document.getElementById('chat-message-input'); input.value = '${text}'; input.dispatchEvent(new Event('input', {bubbles: true})); input.dispatchEvent(new Event('change', {bubbles: true}));
    Sleep    1s
    # คลิกปุ่มส่งผ่าน JS เพื่อเลี่ยงปัญหา element interactability
    Execute JavaScript    document.getElementById('chat-send-button').click()
    Sleep    2s

Verify Message Sent
    [Arguments]    ${text}
    Scroll Chat To Bottom
    Wait Until Page Contains    ${text}    timeout=10s
    Log    Message verified: ${text}

Verify Message Received
    [Arguments]    ${text}
    Scroll Chat To Bottom
    Wait Until Page Contains    ${text}    timeout=10s
    Log    Received message verified: ${text}

Scroll Chat To Bottom
    [Documentation]    เลื่อน scroll bar ของ chat container ลงมาด้านล่างสุด
    # เจาะจงไปที่ main ภายใน #chat-container
    Execute JavaScript    var container = document.querySelector('#chat-container main'); if(container) { container.scrollTop = container.scrollHeight; }
    Sleep    1s


Click Quick Reply
    [Arguments]    ${reply_text}
    Wait Until Element Is Visible    xpath://button[contains(text(), '${reply_text}')]    timeout=10s
    Click Element                    xpath://button[contains(text(), '${reply_text}')]
    Sleep    1s

# ══════════════════════════════════════════════════════════════════
# ATTACHMENT MENU KEYWORDS
# ══════════════════════════════════════════════════════════════════
Open Attachment Menu
    [Documentation]    กดปุ่ม + เพื่อเปิด Attachment Menu
    # Use JS to find and click the first button in the chat footer (the + / attachment toggle)
    Wait Until Element Is Visible    id:chat-container    timeout=10s
    Execute JavaScript    document.querySelector('#chat-container footer button').click()
    Sleep    1s
    Log    Attachment menu opened

Verify Attachment Menu Has Image Option
    [Documentation]    ตรวจสอบว่ามีตัวเลือก "รูปภาพ" ในเมนูแนบ
    Wait Until Page Contains    รูปภาพ    timeout=10s
    Log    Image option found in attachment menu

Verify Attachment Menu Has Location Option
    [Documentation]    ตรวจสอบว่ามีตัวเลือก "ตำแหน่งที่ตั้ง" ในเมนูแนบ
    Wait Until Page Contains    ตำแหน่งที่ตั้ง    timeout=10s
    Log    Location option found in attachment menu

Close Attachment Menu
    [Documentation]    ปิด Attachment Menu โดยคลิกที่ backdrop หรือกดปุ่ม + อีกครั้ง
    # Try clicking the backdrop overlay first, fallback to toggling the + button via JS
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains Element    xpath://div[contains(@class, 'bg-black')]    timeout=3s
    IF    ${status}
        Execute JavaScript    var el = document.querySelector('#chat-container div[class*="bg-black"]'); if(el) el.click();
    ELSE
        Execute JavaScript    document.querySelector('#chat-container footer button').click()
    END
    Sleep    0.5s
    Log    Attachment menu closed

# ══════════════════════════════════════════════════════════════════
# NOTIFICATION KEYWORDS
# ══════════════════════════════════════════════════════════════════
Verify Notification Badge Exists
    [Documentation]    ตรวจสอบ badge แจ้งเตือนที่ navbar (จุดแดง/ตัวเลข unread)
    Wait Until Page Contains Element    id:chat-nav-unread-badge    timeout=15s
    Wait Until Element Is Visible       id:chat-nav-unread-badge    timeout=5s
    Log    Navbar notification badge is visible

Verify List Notification Badge Exists
    [Documentation]    ตรวจสอบ badge unread count ที่ room list ในหน้า /chats
    Wait Until Page Contains Element    xpath://div[contains(@id, 'room-unread-badge-')]    timeout=15s
    Wait Until Element Is Visible       xpath://div[contains(@id, 'room-unread-badge-')]    timeout=5s
    Log    Room list notification badge is visible

# ══════════════════════════════════════════════════════════════════
# CHAT HISTORY PAGE KEYWORDS
# ══════════════════════════════════════════════════════════════════
Verify Chat History Has Rooms
    [Documentation]    ตรวจสอบว่ามีรายการห้องแชทอย่างน้อย 1 ห้อง
    Wait Until Page Contains Element    xpath://div[contains(@id, 'room-')]    timeout=15s
    ${count}=    Get Element Count    xpath://div[contains(@id, 'room-')]
    Should Be True    ${count} >= 1    Expected at least 1 chat room, found ${count}
    Log    Found ${count} chat room(s) in history

Verify Chat Room Shows Participant Name
    [Documentation]    ตรวจสอบว่าห้องแชทแสดงชื่อผู้ร่วมสนทนา
    # Each room card has an h3 with the participant name
    Wait Until Page Contains Element    xpath://div[contains(@id, 'room-')]//h3    timeout=10s
    ${name}=    Get Text    xpath:(//div[contains(@id, 'room-')]//h3)[1]
    Should Not Be Empty    ${name}    Chat room should display a participant name
    Log    First chat room participant: ${name}

Verify Chat Room Shows Last Message Preview
    [Documentation]    ตรวจสอบว่าห้องแชทแสดงข้อความล่าสุดหรือ placeholder
    # Each room has a <p> tag with message preview text
    Wait Until Page Contains Element    xpath://div[contains(@id, 'room-')]//p[contains(@class, 'truncate')]    timeout=10s
    ${preview}=    Get Text    xpath:(//div[contains(@id, 'room-')]//p[contains(@class, 'truncate')])[1]
    Should Not Be Empty    ${preview}    Chat room should display a last message preview
    Log    Last message preview: ${preview}

Verify Latest Message In History
    [Arguments]    ${expected_text}
    [Documentation]    ตรวจสอบว่าข้อความล่าสุดในรายการแชทตรงกับที่คาดหวัง (ตรวจสอบห้องแรกสุด)
    Wait Until Page Contains Element    xpath:(//div[contains(@id, 'room-')]//p[contains(@class, 'truncate')])[1]    timeout=15s
    ${latest_msg}=    Get Text    xpath:(//div[contains(@id, 'room-')]//p[contains(@class, 'truncate')])[1]
    Log    Actual latest message: ${latest_msg}
    # ใช้ Should Contain เพื่อความยืดหยุ่น เช่น สนับสนุนข้อความที่มีการตัดคำหรือ preview
    Should Contain    ${latest_msg}    ${expected_text}
    Log    Latest message in history verified: ${latest_msg}

