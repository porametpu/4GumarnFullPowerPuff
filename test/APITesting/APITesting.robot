*** Settings ***
Library          RequestsLibrary
Library          Collections
Library          String

Test Setup       Create Session    alias=api    url=http://localhost:3000    disable_warnings=1
Test Teardown    Delete All Sessions

*** Variables ***
${VALID_EMAIL}              test555@test.com
${INVALID_EMAIL}            not-match@example.com

${BEARER_TOKEN}             eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjbWxyeGJnZnkwMDAzb2hmenNpeTNiYzhhIiwicm9sZSI6IlBBU1NFTkdFUiIsImlhdCI6MTc3MTQxMjU5NCwiZXhwIjoxNzcxNDE2MTk0fQ.TMyZBBOyPWORmP55w-nUoVWn_6XGO-uqUxjU0sXckmw

${EXPECTED_MESSAGE_SUCCESS}    คำขอการลบบัญชีสำเร็จ
${EXPECTED_DETAIL_SUCCESS}     บัญชีจะถูกลบอย่างถาวรหลังจาก 90 วัน
${EXPECTED_MESSAGE_FAIL}       อีเมลไม่ตรงกับบัญชีนี้

${DELETE_ENDPOINT}             /api/users/delete-account

*** Test Cases ***
TC-001 POST Request Delete user - Successfully sent request
    [Tags]          smoke    delete-account    positive
    [Documentation]    ทดสอบการส่งคำขอลบบัญชีด้วย email ที่ถูกต้อง ควรได้ 202 Accepted

    ${headers}=    Create Dictionary
    ...    Authorization    Bearer ${BEARER_TOKEN}
    ...    Content-Type     application/json

    ${payload}=    Create Dictionary    email=${VALID_EMAIL}

    ${response}=    POST On Session
    ...    api
    ...    ${DELETE_ENDPOINT}
    ...    json=${payload}
    ...    headers=${headers}
    ...    expected_status=202

    # ตรวจสอบ response
    Should Be Equal As Integers       ${response.status_code}          202
    Should Contain                    ${response.headers}[Content-Type]    application/json    ignore_case=True

    ${resp_json}=    Set Variable    ${response.json()}

    Should Contain                    ${resp_json}    message
    Should Contain                    ${resp_json}    detail
    Should Be Equal As Strings        ${resp_json}[message]    ${EXPECTED_MESSAGE_SUCCESS}
    Should Be Equal As Strings        ${resp_json}[detail]     ${EXPECTED_DETAIL_SUCCESS}


TC-002 POST Request Delete user with wrong email - Email not match
    [Tags]          delete-account    negative
    [Documentation]    ทดสอบส่ง email ผิด ควรได้ 400 Bad Request และข้อความแจ้งเตือน

    ${headers}=    Create Dictionary
    ...    Authorization    Bearer ${BEARER_TOKEN}
    ...    Content-Type     application/json

    ${payload}=    Create Dictionary    email=${INVALID_EMAIL}

    ${response}=    POST On Session
    ...    api
    ...    ${DELETE_ENDPOINT}
    ...    json=${payload}
    ...    headers=${headers}
    ...    expected_status=400

    Should Be Equal As Integers       ${response.status_code}          400
    Should Contain                    ${response.headers}[Content-Type]    application/json    ignore_case=True

    ${resp_json}=    Set Variable    ${response.json()}

    Should Contain                    ${resp_json}    message
    Should Be Equal As Strings        ${resp_json}[message]    ${EXPECTED_MESSAGE_FAIL}