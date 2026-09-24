"""Exercise the real installer and restore scripts in disposable fake Sider folders."""
import hashlib,json,subprocess,unittest,uuid
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'test-output'/uuid.uuid4().hex
MANIFEST=json.loads((ROOT/'manifest.json').read_text())

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def put(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(data)
def snapshot(folder):
    return {p.relative_to(folder).as_posix():sha(p) for p in folder.rglob('*') if p.is_file() and 'TouchlineMenu-backups' not in p.parts}
def ps(script,*args):
    return subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(script),*map(str,args)],capture_output=True,text=True)

class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.game=RUN/self._testMethodName/'SiderAddons'
        put(self.game/'sider.ini',b'[sider]\r\n; user settings\r\nlivecpk.enabled = 1\r\nlua.enabled = 1\r\n')
        put(self.game/'livecpk/Unrelated/example.bin',b'preserve this other mod')

    def install(self):
        result=ps(ROOT/'Install.ps1','-SiderDir',self.game)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        return sorted((self.game/'TouchlineMenu-backups').iterdir())[-1]

    def restore(self,backup):return ps(ROOT/'Uninstall.ps1','-SiderDir',self.game,'-BackupDirectory',backup)

    def test_fresh_install_and_restore(self):
        before=snapshot(self.game);backup=self.install()
        for entry in MANIFEST['files']:self.assertEqual(sha(self.game/entry['path']),entry['sha256'])
        ini=(self.game/'sider.ini').read_text()
        self.assertIn('cpk.root = ".\\livecpk\\TouchlinePrologue2"',ini)
        self.assertIn('lua.module = "TouchlineMenuColors.lua"',ini)
        self.assertFalse((self.game/'livecpk/MenuC1987').exists())
        self.assertFalse((self.game/'modules/UIColors.lua').exists())
        result=self.restore(backup);self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(snapshot(self.game),before)

    def test_upgrade_preserves_existing_files_in_backup(self):
        target=self.game/'livecpk/TouchlinePrologue2/common/menu/general/schedule.bin'
        put(target,b'previous working schedule')
        put(self.game/'modules/UIColors.lua',b'-- user original module\n')
        put(self.game/'content/ui-colors/map_exe.txt',b'original shared palette')
        put(self.game/'livecpk/MenuC1987/preserve.bin',b'original pack')
        put(self.game/'livecpk/UIColors/preserve.bin',b'original colors')
        ini=self.game/'sider.ini';put(ini,ini.read_bytes()+b'cpk.root = ".\\livecpk\\TouchlinePrologue2"\r\ncpk.root = ".\\livecpk\\MenuC1987"\r\ncpk.root = ".\\livecpk\\UIColors"\r\nlua.module = "UIColors.lua"\r\n')
        before=snapshot(self.game);backup=self.install()
        self.assertEqual((self.game/'sider.ini').read_text().count('TouchlinePrologue2'),1)
        active=[line for line in (self.game/'sider.ini').read_text().splitlines() if not line.lstrip().startswith(';')]
        self.assertFalse(any('MenuC1987' in line or '"UIColors.lua"' in line or 'livecpk\\UIColors' in line for line in active))
        self.assertEqual((self.game/'content/ui-colors/map_exe.txt').read_bytes(),b'original shared palette')
        result=self.restore(backup);self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(snapshot(self.game),before)

    def test_restore_refuses_later_changes_without_partial_restore(self):
        backup=self.install();put(self.game/'content/touchline-menu/map_exe.txt',b'later user change')
        before=snapshot(self.game);result=self.restore(backup)
        self.assertNotEqual(result.returncode,0);self.assertIn('Changed since installation',result.stderr)
        self.assertEqual(snapshot(self.game),before)

    def test_unknown_retired_override_is_preserved(self):
        put(self.game/'livecpk/TouchlinePrologue2/common/menu/parts/teamPower.bin',b'user-owned modification')
        before=snapshot(self.game);result=ps(ROOT/'Install.ps1','-SiderDir',self.game)
        self.assertNotEqual(result.returncode,0);self.assertIn('independently edited',result.stderr)
        self.assertEqual(snapshot(self.game),before)

    def test_corrupt_payload_rejected_before_install(self):
        package=RUN/'corrupt-package'
        for name in ['Install.ps1','scripts/Common.ps1']:put(package/name,(ROOT/name).read_bytes())
        entry=dict(MANIFEST['files'][0]);put(package/entry['path'],b'corrupt')
        put(package/'manifest.json',json.dumps({'version':'test','files':[entry],'retired':[]}).encode())
        before=snapshot(self.game);result=ps(package/'Install.ps1','-SiderDir',self.game)
        self.assertNotEqual(result.returncode,0);self.assertIn('checksum failed',result.stderr)
        self.assertEqual(snapshot(self.game),before)
        self.assertFalse((self.game/'TouchlineMenu-backups').exists())

if __name__=='__main__':unittest.main(verbosity=2)
