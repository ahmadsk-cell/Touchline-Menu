"""Optional developer test: pip install lupa. No game process is accessed."""
import re,unittest
from pathlib import Path
from lupa.luajit21 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]

class ColorRuntimeTests(unittest.TestCase):
    def test_standalone_init_and_reload_without_commonlib_or_other_mods(self):
        lua=LuaRuntime(encoding=None)
        lua.globals()[b'root_path']=(str(ROOT)+'\\').encode()
        lua.globals()[b'module_path']=str(ROOT/'modules/TouchlineMenuColors.lua').encode()
        lua.execute(br'''
            writes = {}; write_count = 0; handlers = {}
            log = function(_) end
            memory = {
                search_process = function(pattern)
                    assert(pattern == "\x10\x10\x10\xFF\xFF\xFF\xFF\xFF\x00\x44\x93\xFF")
                    return 4096
                end,
                read = function(address, count)
                    assert(count == 4)
                    return writes[address] or "\x10\x10\x10\xFF"
                end,
                write = function(address, value)
                    assert(address >= 4096 and address < 4096+80*4 and address%4 == 0)
                    assert(#value == 4)
                    writes[address] = value; write_count = write_count+1
                end,
                pack = function(kind, value)
                    assert(kind == "u32")
                    local bytes = {}
                    for i=1,4 do bytes[i]=string.char(value%256);value=math.floor(value/256) end
                    return table.concat(bytes)
                end,
                unpack = function(kind,value) assert(kind == "b");return value end,
                hex = function(value)
                    if type(value) == "number" then return string.format("%x",value) end
                    return (value:gsub(".",function(c)return string.format("%02x",c:byte())end))
                end,
            }
            ctx = {sider_dir=root_path, register=function(event,handler) handlers[event]=handler end}
            module = assert(loadfile(module_path))()
            module.init(ctx)
            assert(ctx.common_lib == nil)
            assert(module.bins_processed == true)
        ''')
        expected={int(n):bytes.fromhex(color) for n,color in re.findall(r'^\s*(\d+)\s*,\s*([0-9a-fA-F]{8})', (ROOT/'content/touchline-menu/map_exe.txt').read_text(),re.M)}
        self.assertEqual(lua.globals()[b'write_count'],len(expected))
        for index,color in expected.items():self.assertEqual(lua.globals()[b'writes'][4096+(index-1)*4],color)
        lua.execute(b'handlers.key_down(ctx,0x30)')
        self.assertEqual(lua.globals()[b'write_count'],2*len(expected))
        for index,color in expected.items():self.assertEqual(lua.globals()[b'writes'][4096+(index-1)*4],color)

if __name__=='__main__':unittest.main(verbosity=2)
