*** Settings ***
Library    SeleniumLibrary
Test Teardown    Close Browser And Capture
Suite Teardown    Print Report Paths

*** Variables ***
${BASE_URL}          http://localhost:3001
${BROWSER}           chrome
${LOGIN_EMAIL}       %{TEST_EMAIL}
${LOGIN_PASSWORD}    %{TEST_PASSWORD}
${WRONG_EMAIL}       not-match@example.com
${DELETE_EMAIL_INPUT}    xpath=//input[@placeholder='กรอกอีเมลของคุณเพื่อยืนยัน']
${DELETE_BUTTON}    xpath=//button[normalize-space()='ลบบัญชีถาวร']

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

