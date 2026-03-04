import subprocess
import json
import os

class CleanupLibrary:
    def __init__(self):
        self.helper_path = os.path.join(os.path.dirname(__file__), 'cleanup_helper.js')

    def _run_helper(self, action, arg1=None, arg2=None):
        cmd = ['node', self.helper_path, action]
        if arg1:
            cmd.append(arg1)
        if arg2:
            cmd.append(arg2)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"Helper failed: {result.stderr}")
        
        # Split by newline and take the last non-empty line as the "result"
        # Diagnostic logs are on earlier lines
        lines = [line.strip() for line in result.stdout.split('\n') if line.strip()]
        if not lines:
            return ""
        return lines[-1]

    def setup_cleanup_test_data(self, test_case):
        output = self._run_helper('setup', test_case)
        return json.loads(output)

    def run_cleanup_cron_job(self):
        output = self._run_helper('run')
        return int(output)

    def verify_cleanup_state(self, test_case, id_or_ids):
        arg2 = json.dumps(id_or_ids)
        output = self._run_helper('verify', test_case, arg2)
        return output.lower() == 'true'
