*** Settings ***
Library    SeleniumLibrary    screenshot_root_directory=${CURDIR}/screenshots
Library    OperatingSystem

*** Variables ***
${URL}             http://localhost:3001
${BROWSER}         Chrome

*** Keywords ***
Open Browser To Home Page
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${chrome_options}    add_argument    --no-sandbox
    Call Method    ${chrome_options}    add_argument    --disable-dev-shm-usage
    Call Method    ${chrome_options}    add_argument    --headless
    Call Method    ${chrome_options}    add_argument    --disable-gpu
    Call Method    ${chrome_options}    add_argument    --window-size\=1920,1080
    # Add longer timeout to handle slow page loads in headless
    Open Browser    ${URL}    ${BROWSER}    options=${chrome_options}
    Maximize Browser Window
    Set Selenium Speed    0.2s
    Set Selenium Timeout    30s
    Register Keyword To Run On Failure    Capture Page Screenshot

Setup Test Session
    [Arguments]    ${email}    ${password}
    Open Browser To Home Page
    Login User    ${email}    ${password}

Teardown Test Session
    Run Keyword And Ignore Error    Logout User
    Close All Browsers

Login User
    [Arguments]    ${email}    ${password}
    Go To    ${URL}/login
    Wait Until Page Contains Element    id:identifier    timeout=15s
    # Clear and set input values via JS to ensure Vue v-model reactivity
    Execute JavaScript    var el = document.getElementById('identifier'); el.value = ''; el.dispatchEvent(new Event('input', {bubbles: true}));
    Execute JavaScript    var el = document.getElementById('identifier'); el.focus(); el.value = '${email}'; el.dispatchEvent(new Event('input', {bubbles: true}));
    Execute JavaScript    var el = document.getElementById('password'); el.focus(); el.value = '${password}'; el.dispatchEvent(new Event('input', {bubbles: true}));
    Sleep    1s
    # Submit the form via JS
    Execute JavaScript    document.querySelector('#loginForm button[type="submit"]').click()
    # Verify login by confirming we are no longer on the login page
    Wait Until Location Does Not Contain    /login    timeout=20s
    Sleep    1s
    Log    Login successful for ${email}

Logout User
    Log    Attempting to logout
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains    เข้าสู่ระบบ    timeout=5s
    IF    ${status}
        Return From Keyword
    END
    
    # Try all logout buttons via JS with null checks
    Execute JavaScript    var b = document.getElementById('logout-button') || document.getElementById('mobile-logout-button') || document.getElementById('admin-logout-button'); if(b) b.click();
    
    # If that didn't work, try opening dropdown first
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains    เข้าสู่ระบบ    timeout=5s
    IF    not ${status}
        Execute JavaScript    var t = document.getElementById('user-dropdown-trigger') || document.getElementById('admin-dropdown-trigger'); if(t) t.click();
        Sleep    0.5s
        Execute JavaScript    var b = document.getElementById('logout-button') || document.getElementById('mobile-logout-button') || document.getElementById('admin-logout-button'); if(b) b.click();
    END
    
    # Final check
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s
    Log    Logged out successfully
