*** Settings ***
Documentation     Test Suite for Account Cleanup Cron Job
Library           CleanupLibrary.py

*** Test Cases ***
# ══════════════════════════════════════════════════════════════════
# 1) Delete Account With Related Record
# ══════════════════════════════════════════════════════════════════
Delete Account With Related Record
    [Documentation]    ลบบัญชีที่มีข้อมูลอื่นๆเก็บอยู่ด้วย (Booking, Vehicle, Route, Notification)
    ${user_info}=    Setup Cleanup Test Data    related_records
    ${deleted_count}=    Run Cleanup Cron Job
    Should Be True    ${deleted_count} >= 1
    ${is_deleted}=    Verify Cleanup State    related_records    ${user_info['userId']}
    Should Be True    ${is_deleted}    User should be deleted from DB

# ══════════════════════════════════════════════════════════════════
# 2) Delete Many Account
# ══════════════════════════════════════════════════════════════════
Delete Many Account
    [Documentation]    ลบผู้ใช้หลายบัญชีพร้อมกัน (User1, User2, User3 : Deleted At > 90 วัน, isActive=false)
    ${user_ids}=    Setup Cleanup Test Data    many_accounts
    ${deleted_count}=    Run Cleanup Cron Job
    Should Be True    ${deleted_count} >= 3
    ${is_deleted}=    Verify Cleanup State    many_accounts    ${user_ids}
    Should Be True    ${is_deleted}    All batch users should be deleted

# ══════════════════════════════════════════════════════════════════
# 3) No Account Delete
# ══════════════════════════════════════════════════════════════════
No Account Delete
    [Documentation]    ไม่มีผู้ใช้ที่ถึงกำหนดลบ (Deleted At < 90 วัน)
    ${user_id}=    Setup Cleanup Test Data    no_delete
    ${deleted_count}=    Run Cleanup Cron Job
    # We don't assert 0 because there might be other leftover data in DB, 
    # but we verify our specific user is NOT deleted.
    ${is_present}=    Verify Cleanup State    no_delete    ${user_id}
    Should Be True    ${is_present}    User deleted less than 90 days ago should still exist

# ══════════════════════════════════════════════════════════════════
# 4) Delete Account But isActive=true
# ══════════════════════════════════════════════════════════════════
Delete Account But isActive=true
    [Documentation]    ลบบัญชีผู้ใช้ที่มี Deleted At > 90 วัน แต่ isActive=true (ควรถูกยกเว้น)
    ${user_id}=    Setup Cleanup Test Data    active_account
    ${deleted_count}=    Run Cleanup Cron Job
    ${is_present}=    Verify Cleanup State    active_account    ${user_id}
    Should Be True    ${is_present}    Active user should still exist even if deletedAt is old
