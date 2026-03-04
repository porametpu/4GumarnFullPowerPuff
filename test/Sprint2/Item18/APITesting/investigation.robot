*** Settings ***
Library    RequestsLibrary
Library    Collections

Suite Setup    Login Admin


*** Variables ***
${BASE_URL}        http://localhost:3000/api
${ADMIN_EMAIL}     admin@example.com
${ADMIN_PASSWORD}  123456789

${START_DATE}      2026-03-01
${END_DATE}        2026-03-05

${INVALID_START}   2026-03-10
${INVALID_END}     2026-03-01

${INVALID_ID}      invalid123


*** Keywords ***

Login Admin
    Create Session    api    ${BASE_URL}

    ${body}=    Create Dictionary
    ...    email=${ADMIN_EMAIL}
    ...    password=${ADMIN_PASSWORD}

    ${res}=    POST On Session
    ...    api
    ...    /auth/login
    ...    json=${body}

    Should Be Equal As Integers    ${res.status_code}    200

    ${json}=    Set Variable    ${res.json()}
    ${token}=    Set Variable    ${json["data"]["token"]}

    Set Suite Variable    ${TOKEN}    ${token}


Get Admin Header
    ${headers}=    Create Dictionary
    ...    Authorization=Bearer ${TOKEN}

    RETURN    ${headers}


Get Investigation Id
    ${headers}=    Get Admin Header

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations
    ...    headers=${headers}

    ${json}=    Set Variable    ${res.json()}
    ${id}=    Set Variable    ${json["data"][0]["id"]}

    RETURN    ${id}


*** Test Cases ***

TC-01 Login Success
    Should Not Be Empty    ${TOKEN}


TC-02 Create Investigation Success
    ${headers}=    Get Admin Header

    ${body}=    Create Dictionary
    ...    authorityName=kk police
    ...    bookingId=testBooking
    ...    startDate=${START_DATE}
    ...    endDate=${END_DATE}

    ${res}=    POST On Session
    ...    api
    ...    /admin/investigations
    ...    headers=${headers}
    ...    json=${body}
    ...    expected_status=any

    Should Not Be Equal As Integers    ${res.status_code}    500


TC-03 Missing Required Field
    ${headers}=    Get Admin Header

    ${body}=    Create Dictionary
    ...    authorityName=kk police

    ${res}=    POST On Session
    ...    api
    ...    /admin/investigations
    ...    headers=${headers}
    ...    json=${body}
    ...    expected_status=any

    Should Not Be Equal As Integers    ${res.status_code}    200


TC-04 Invalid Date Range
    ${headers}=    Get Admin Header

    ${body}=    Create Dictionary
    ...    authorityName=kk police
    ...    bookingId=testBooking
    ...    startDate=${INVALID_START}
    ...    endDate=${INVALID_END}

    ${res}=    POST On Session
    ...    api
    ...    /admin/investigations
    ...    headers=${headers}
    ...    json=${body}
    ...    expected_status=any

    Should Not Be Equal As Integers    ${res.status_code}    200


TC-05 Get Investigation List
    ${headers}=    Get Admin Header

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations
    ...    headers=${headers}

    Should Be Equal As Integers    ${res.status_code}    200


TC-06 Get Investigation Detail
    ${headers}=    Get Admin Header
    ${id}=    Get Investigation Id

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations/${id}
    ...    headers=${headers}

    Should Be Equal As Integers    ${res.status_code}    200


TC-07 Export Chat Log Success
    ${headers}=    Get Admin Header
    ${id}=    Get Investigation Id

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations/${id}/export
    ...    headers=${headers}

    Should Be Equal As Integers    ${res.status_code}    200


TC-08 Export Without Token
    ${id}=    Get Investigation Id

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations/${id}/export
    ...    expected_status=any

    Should Be Equal As Integers    ${res.status_code}    401


TC-09 Export Invalid Token
    ${headers}=    Create Dictionary
    ...    Authorization=Bearer invalidtoken

    ${id}=    Get Investigation Id

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations/${id}/export
    ...    headers=${headers}
    ...    expected_status=any

    Should Be Equal As Integers    ${res.status_code}    401


TC-10 Export Invalid Investigation ID
    ${headers}=    Get Admin Header

    ${res}=    GET On Session
    ...    api
    ...    /admin/investigations/${INVALID_ID}/export
    ...    headers=${headers}
    ...    expected_status=any

    Should Not Be Equal As Integers    ${res.status_code}    200