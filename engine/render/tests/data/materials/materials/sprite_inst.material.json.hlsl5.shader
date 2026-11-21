{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "hlsl5",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _443_lit : packoffset(c0);\n    float4 _443_ambient : packoffset(c1);\n    float4 _443_normal_uv : packoffset(c2);\n    float4 _443_flat_ambient : packoffset(c3);\n    float4 _443_light_map : packoffset(c4);\n    float4 _443_light_pos[16] : packoffset(c5);\n    float4 _443_light_color[16] : packoffset(c21);\n    float4 _443_light_shadow_v[16] : packoffset(c37);\n    float4 _443_fog_col : packoffset(c53);\n    float4 _443_fog_b : packoffset(c54);\n    float4 _443_fog_c : packoffset(c55);\n    float4 _443_fog_eye : packoffset(c56);\n    float4 _443_fa_time : packoffset(c57);\n    float4 _443_fa_target : packoffset(c58);\n    float4 _443_fx_emit : packoffset(c59);\n    float4 _443_fx_emit_uv : packoffset(c60);\n    float4 _443_fx_rim : packoffset(c61);\n    float4 _443_fx_rim_uv : packoffset(c62);\n    float4 _443_light_cookie[16] : packoffset(c63);\n    float4 _443_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _531_boost : packoffset(c0);\n    float _531_fa_pad0 : packoffset(c0.y);\n    float _531_fa_pad1 : packoffset(c0.z);\n    float _531_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _376 = fa_linear_to_srgb(param);\n        c = _376;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _384 = fa_srgb_to_linear(param_1);\n            c = _384;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _395 = tex.Sample(smp, p);\n    float3 param = _395.xyz;\n    float param_1 = xform.y;\n    float3 _405 = fa_tex_fix(param, param_1);\n    return float4(_405, _395.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _120 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_120.x * 255.0f) + 0.5f) * 256.0f) + floor((_120.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _144 = length(d);\n    if (_144 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _158 = atan2(d.y, d.x);\n    float a = _158;\n    float _161;\n    if (_158 < 0.0f)\n    {\n        _161 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _161 = a;\n    }\n    a = _161;\n    float _173 = _161 * 162.9746551513671875f;\n    float _178 = min(floor(_173), 1023.0f);\n    float _185 = _178 + 1.0f;\n    float i1 = _185;\n    if (_185 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _178;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _144) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _144) + 0.5f, 0.0f, 1.0f), _173 - _178);\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _248 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _252 = _248.x + 0.5f;\n    float2 c = float2(_252, 0.5f - _248.y);\n    bool _260 = _252 >= 0.0f;\n    bool _266;\n    if (_260)\n    {\n        _266 = c.x <= 1.0f;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y >= 0.0f;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    bool _278;\n    if (_272)\n    {\n        _278 = c.y <= 1.0f;\n    }\n    else\n    {\n        _278 = _272;\n    }\n    float2 _280 = c;\n    float2 _285 = clamp(_280, 0.001953125f.xx, 0.998046875f.xx);\n    c = _285;\n    return float3(cell.x + (_285.x * cell.w), cell.y + (_285.y * cell.z), float(_278));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_443_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _443_light_cookie[i];\n    float4 param_1 = _443_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _570 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _570.xy, 0.0f);\n    return cookie_value(param_3) * _570.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _592 = _443_lit.y > 0.5f;\n    if (_592)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _443_normal_uv.xy) + _443_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _616 = fa_tex_fix(param, param_1);\n        float3 _620 = (_616 * 2.0f) - 1.0f.xxx;\n        float _627 = cos(params.y);\n        float _629 = sin(params.y);\n        n = normalize(float3((float2(_627, _629) * _620.x) + ((float2(-_629, _627) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _620.y), max(_620.z, 0.0500000007450580596923828125f)));\n    }\n    bool _663 = !_592;\n    bool _669;\n    if (_663)\n    {\n        _669 = _443_lit.z > 0.5f;\n    }\n    else\n    {\n        _669 = _663;\n    }\n    float3 _672;\n    if (_669)\n    {\n        _672 = _443_flat_ambient.xyz;\n    }\n    else\n    {\n        _672 = _443_ambient.xyz;\n    }\n    float3 total = _672;\n    bool _689;\n    if (_669)\n    {\n        _689 = _443_lit.z < 1.5f;\n    }\n    else\n    {\n        _689 = _669;\n    }\n    if (_689)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _443_light_map.xy, 0.0f).xyz * _443_light_map.z);\n    }\n    float3 l;\n    float _813;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _727;\n        if (!_669)\n        {\n            _727 = float(i) >= _443_lit.x;\n        }\n        else\n        {\n            _727 = _669;\n        }\n        if (_727)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_443_light_pos[i].w < 0.0f)\n        {\n            l = _443_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _753 = _443_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_753) / max(_443_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _443_light_color[i].w);\n            float3 _773 = float3(_753, _443_light_pos[i].z);\n            l = _773 / max(length(_773), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_443_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _443_light_shadow_v[i].x;\n                float2 param_3 = -_753;\n                float param_4 = _443_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            float2 param_6 = -_753;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_592)\n        {\n            _813 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _813 = 1.0f;\n        }\n        total += (_443_light_color[i].xyz * (att * _813));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _421 = fa_srgb_to_linear(param);\n        c = _421;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1059 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1063 = uv * _1059;\n    float _1069 = _1059.x;\n    float _1071 = _1059.y;\n    float _1073 = clamp(shape_rs.x, 0.0f, min(_1069, _1071));\n    float2 _1084 = (abs(_1063) - _1059) + _1073.xx;\n    float d = (length(max(_1084, 0.0f.xx)) + min(max(_1084.x, _1084.y), 0.0f)) - _1073;\n    float ax = params.y;\n    bool _1105 = params.y > 15.0f;\n    if (_1105)\n    {\n        ax -= 20.0f;\n    }\n    float _1116;\n    if (ax <= (-1.5f))\n    {\n        _1116 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1116 = 0.0f;\n    }\n    if (_1116 > 0.0f)\n    {\n        float _1130 = _1116 * 0.5f;\n        d = abs(d + _1130) - _1130;\n    }\n    float _1138 = fwidth(d);\n    float _1139 = max(_1138, 9.9999997473787516355514526367188e-05f);\n    float _1149 = clamp(0.5f - (d / max(shape_rs.y, _1139)), 0.0f, 1.0f);\n    float _1154;\n    if (shape_rs.y > _1139)\n    {\n        _1154 = (_1149 * _1149) * (3.0f - (2.0f * _1149));\n    }\n    else\n    {\n        _1154 = _1149;\n    }\n    float4 c = color;\n    bool _1176 = (_1116 <= 0.0f) && (ax > (-0.5f));\n    if (_1176)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1191 = cos(ax);\n            float _1193 = sin(ax);\n            g = ((dot(_1063, float2(_1191, _1193)) / max((abs(_1191) * _1069) + (abs(_1193) * _1071), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1105)\n        {\n            float4 _1236 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1236;\n            float3 param = _1236.xyz;\n            float param_1 = xform.y;\n            float3 _1243 = fa_tex_fix(param, param_1);\n            float4 _2031 = c;\n            _2031.x = _1243.x;\n            _2031.y = _1243.y;\n            _2031.z = _1243.z;\n            c = _2031;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1255 = scene_rgb(param_2);\n            float4 _1280 = lerp(float4(color.xyz * color.w, color.w), float4(_1255 * color2.w, color2.w), g.xxxx);\n            float _1282 = _1280.w;\n            float3 _1285;\n            if (_1282 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1285 = _1280.xyz / _1282.xxx;\n            }\n            else\n            {\n                _1285 = color.xyz;\n            }\n            c = float4(_1285, _1282);\n        }\n    }\n    float4 _2040 = c;\n    _2040.w = _2040.w * _1154;\n    c = _2040;\n    if (_1176 || (shape_rs.y > 0.0f))\n    {\n        float _1326 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1335 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1335 + (_1326 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1341 = fa_srgb_to_linear(param_4);\n            float4 _2043 = c;\n            _2043.x = _1341.x;\n            _2043.y = _1341.y;\n            _2043.z = _1341.z;\n            c = _2043;\n        }\n        else\n        {\n            float4 _1351 = c;\n            float3 _1354 = _1351.xyz + (_1326 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2050 = _1351;\n            _2050.x = _1354.x;\n            _2050.y = _1354.y;\n            _2050.z = _1354.z;\n            c = _2050;\n        }\n        float4 _2055 = c;\n        _2055.w = clamp(_2055.w + ((_1326 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2055.w)), 0.0f, 1.0f);\n        c = _2055;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _850 = float2(_443_fx_rim_uv.x, 0.0f);\n    float4 _852 = tex.Sample(smp, uv - _850);\n    float _853 = _852.w;\n    float4 _863 = tex.Sample(smp, uv + _850);\n    float _864 = _863.w;\n    float2 _872 = float2(0.0f, _443_fx_rim_uv.y);\n    float4 _874 = tex.Sample(smp, uv - _872);\n    float _875 = _874.w;\n    float4 _885 = tex.Sample(smp, uv + _872);\n    float _886 = _885.w;\n    float _901 = _853 - _864;\n    float _904 = _886 - _875;\n    float _914 = cos(params.y);\n    float _916 = sin(params.y);\n    float2 _942 = ((float2(_914, _916) * _901) + ((float2(-_916, _914) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _904)) / max(length(float2(_901, _904)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _443_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_443_light_pos[i].w < 0.0f)\n        {\n            to_l = _443_light_pos[i].xy / max(length(_443_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _988 = _443_light_pos[i].xy - world_xy;\n            float _991 = length(_988);\n            att = pow(clamp(1.0f - (_991 / max(_443_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _443_light_color[i].w);\n            to_l = _988 / max(_991, 9.9999997473787516355514526367188e-05f).xx;\n            if (_443_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _443_light_shadow_v[i].x;\n                float2 param_1 = -_988;\n                float param_2 = _443_light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            float2 param_4 = -_988;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (_443_light_color[i].xyz * (att * max(dot(_942, to_l), 0.0f)));\n    }\n    return (sum * _443_fx_rim.xyz) * (a0 * (1.0f - min(min(_853, _864), min(_875, _886))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _449 = gl_FragCoord.xy * _443_fa_target.xy;\n    float _453 = _449.y;\n    return float2(_449.x, lerp(_453, 1.0f - _453, _443_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _494 = base_mode < 0.5f;\n    bool _505;\n    if (!_494)\n    {\n        _505 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _505 = _494;\n    }\n    float _506;\n    if (_505)\n    {\n        _506 = shape_half.x;\n    }\n    else\n    {\n        _506 = 0.0f;\n    }\n    QuadInput _1981 = { uv, color, world_xy, fa_screen_uv(), _443_fa_time.x, base_mode, 0.0f.xxxx, _506 };\n    return _1981;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _427 = scene_rgb(param);\n    return _427;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _534 = fa_scene_rgb(param) * _531_boost;\n    s.color.x = _534.x;\n    s.color.y = _534.y;\n    s.color.z = _534.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1381 = params.x > 31.5f;\n    if (_1381)\n    {\n        mode -= 32.0f;\n    }\n    float _1389 = mode;\n    bool _1391 = _1389 > 15.5f;\n    if (_1391)\n    {\n        mode -= 16.0f;\n    }\n    float _1399 = mode;\n    bool _1401 = _1399 > 7.5f;\n    if (_1401)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1391)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1391)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1463 = tex_color(param_5);\n                float4 _1465 = _1463 * color;\n                float4 param_6 = _1465;\n                float param_7 = mode;\n                float _1472 = _1465.w;\n                frag_color = float4(lit_color(param_6, param_7), _1472);\n                if (_443_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1472;\n                    float param_9 = mode;\n                    float4 _1488 = frag_color;\n                    float3 _1490 = _1488.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1490.x;\n                    frag_color.y = _1490.y;\n                    frag_color.z = _1490.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1520 = length(uv);\n                    float _1523 = fwidth(_1520);\n                    float _1524 = max(_1523, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1520) / _1524) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1520) / _1524) + 0.5f, 0.0f, 1.0f) * clamp(((_1520 - params.y) / _1524) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1564 = clamp(1.0f - _1520, 0.0f, 1.0f);\n                            cov = (_1564 * _1564) * (3.0f - (2.0f * _1564));\n                        }\n                    }\n                    float3 _1573;\n                    if (_1391)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1573 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1573 = color.xyz;\n                    }\n                    frag_color = float4(_1573, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_443_fx_emit.w > 0.5f)\n    {\n        float3 e = _443_fx_emit.xyz;\n        if (_443_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _443_fx_emit_uv.xy) + _443_fx_emit_uv.zw).xyz;\n            float param_13 = _443_fx_emit.w - 2.0f;\n            float3 _1628 = fa_tex_fix(param_12, param_13);\n            e *= _1628;\n        }\n        float4 _1632 = frag_color;\n        float3 _1634 = _1632.xyz + e;\n        frag_color.x = _1634.x;\n        frag_color.y = _1634.y;\n        frag_color.z = _1634.z;\n    }\n    float param_14 = mode;\n    float4 _1961 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _1963 = { _1961 };\n    QuadSurface param_16 = _1963;\n    fragment(param_15, param_16);\n    _1961 = param_16.color;\n    frag_color = param_16.color;\n    if (_1381)\n    {\n        float4 _1660 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1665 = scene_rgb(param_17);\n        float3 _1669 = lerp(_1660.xyz, _1665, color2.w.xxx);\n        frag_color.x = _1669.x;\n        frag_color.y = _1669.y;\n        frag_color.z = _1669.z;\n    }\n    if (_1401)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1693 = _443_fog_col.w > 0.0f;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = _443_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        float3 _1715 = float3(world_xy, world_z) - _443_fog_eye.xyz;\n        float _1722 = dot(_1715, _443_fog_c.xyz);\n        bool _1726 = _443_fog_c.w > 0.5f;\n        float _1727;\n        if (_1726)\n        {\n            _1727 = _1722;\n        }\n        else\n        {\n            _1727 = length(_1715);\n        }\n        float _1739 = _1727 - _443_fog_b.x;\n        if (_1739 > 0.0f)\n        {\n            float _1748 = _443_fog_col.w * _1739;\n            float tau = _1748 * _1748;\n            if (_443_fog_b.y > 0.0f)\n            {\n                float _1764;\n                if (_1726)\n                {\n                    _1764 = world_xy.y - (_443_fog_c.y * _1722);\n                }\n                else\n                {\n                    _1764 = _443_fog_eye.y;\n                }\n                float _1785 = lerp(_1764, world_xy.y, clamp(_443_fog_b.x / _1727, 0.0f, 1.0f));\n                float _1789 = world_xy.y - _1785;\n                float _1794 = _1785 - _443_fog_b.z;\n                float _1799 = world_xy.y - _443_fog_b.z;\n                bool _1802 = _1794 <= 0.0f;\n                bool _1803 = !_1802;\n                bool _1809;\n                if (_1803)\n                {\n                    _1809 = _443_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1809 = _1802;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = _443_fog_b.y;\n                }\n                else\n                {\n                    _1810 = _443_fog_b.y * exp(-min(_443_fog_b.w * _1794, 80.0f));\n                }\n                bool _1837;\n                if (_1803)\n                {\n                    _1837 = _443_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1837 = _1802;\n                }\n                float _1838;\n                if (_1837)\n                {\n                    _1838 = _443_fog_b.y * _1794;\n                }\n                else\n                {\n                    _1838 = (_443_fog_b.y * (1.0f - exp(-min(_443_fog_b.w * _1794, 80.0f)))) / _443_fog_b.w;\n                }\n                bool _1863 = _1799 <= 0.0f;\n                bool _1870;\n                if (!_1863)\n                {\n                    _1870 = _443_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1870 = _1863;\n                }\n                float _1871;\n                if (_1870)\n                {\n                    _1871 = _443_fog_b.y * _1799;\n                }\n                else\n                {\n                    _1871 = (_443_fog_b.y * (1.0f - exp(-min(_443_fog_b.w * _1799, 80.0f)))) / _443_fog_b.w;\n                }\n                float _1898;\n                if (abs(_1789) < 0.001000000047497451305389404296875f)\n                {\n                    _1898 = _1810;\n                }\n                else\n                {\n                    _1898 = (_1871 - _1838) / _1789;\n                }\n                tau += (_1739 * max(_1898, 0.0f));\n            }\n            float4 _1921 = frag_color;\n            float3 _1929 = lerp(_1921.xyz, _443_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1929.x;\n            frag_color.y = _1929.y;\n            frag_color.z = _1929.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_443",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_531",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _162_lit : packoffset(c0);\n    float4 _162_ambient : packoffset(c1);\n    float4 _162_normal_uv : packoffset(c2);\n    float4 _162_flat_ambient : packoffset(c3);\n    float4 _162_light_map : packoffset(c4);\n    float4 _162_light_pos[16] : packoffset(c5);\n    float4 _162_light_color[16] : packoffset(c21);\n    float4 _162_light_shadow_v[16] : packoffset(c37);\n    float4 _162_fog_col : packoffset(c53);\n    float4 _162_fog_b : packoffset(c54);\n    float4 _162_fog_c : packoffset(c55);\n    float4 _162_fog_eye : packoffset(c56);\n    float4 _162_fa_time : packoffset(c57);\n    float4 _162_fa_target : packoffset(c58);\n    float4 _162_fx_emit : packoffset(c59);\n    float4 _162_fx_emit_uv : packoffset(c60);\n    float4 _162_fx_rim : packoffset(c61);\n    float4 _162_fx_rim_uv : packoffset(c62);\n    float4 _162_light_cookie[16] : packoffset(c63);\n    float4 _162_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _254_boost : packoffset(c0);\n    float _254_fa_pad0 : packoffset(c0.y);\n    float _254_fa_pad1 : packoffset(c0.z);\n    float _254_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _169 = gl_FragCoord.xy * _162_fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, lerp(_174, 1.0f - _174, _162_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5f;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0f;\n    }\n    QuadInput _367 = { uv, color, world_xy, fa_screen_uv(), _162_fa_time.x, base_mode, 0.0f.xxxx, _229 };\n    return _367;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param) * _254_boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid frag_main()\n{\n    float4 _284 = tex.Sample(smp, uv);\n    float3 param = _284.xyz;\n    float param_1 = xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    frag_color = float4(_293, _284.w) * color;\n    float param_2 = 0.0f;\n    float4 _347 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _349 = { _347 };\n    QuadSurface param_4 = _349;\n    fragment(param_3, param_4);\n    _347 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
