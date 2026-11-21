{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _579_lit : packoffset(c0);\n    float4 _579_ambient : packoffset(c1);\n    float4 _579_normal_uv : packoffset(c2);\n    float4 _579_flat_ambient : packoffset(c3);\n    float4 _579_light_map : packoffset(c4);\n    float4 _579_light_pos[16] : packoffset(c5);\n    float4 _579_light_color[16] : packoffset(c21);\n    float4 _579_light_shadow_v[16] : packoffset(c37);\n    float4 _579_fog_col : packoffset(c53);\n    float4 _579_fog_b : packoffset(c54);\n    float4 _579_fog_c : packoffset(c55);\n    float4 _579_fog_eye : packoffset(c56);\n    float4 _579_fa_time : packoffset(c57);\n    float4 _579_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _665_boost : packoffset(c0);\n    float _665_fa_pad0 : packoffset(c0.y);\n    float _665_fa_pad1 : packoffset(c0.z);\n    float _665_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _513 = fa_linear_to_srgb(param);\n        c = _513;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _521 = fa_srgb_to_linear(param_1);\n            c = _521;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _532 = tex.Sample(smp, p);\n    float3 param = _532.xyz;\n    float param_1 = xform.y;\n    float3 _542 = fa_tex_fix(param, param_1);\n    return float4(_542, _532.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _118 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_118.x * 255.0f) + 0.5f) * 256.0f) + floor((_118.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _221 = floor(tt);\n    float _231 = _221 - (1024.0f * floor(_221 * 0.0009765625f));\n    float _234 = _231 + 1.0f;\n    float i1 = _234;\n    if (_234 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _231;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _221);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _271 = length(d);\n    float result = 1.0f;\n    if (_271 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _282 = atan2(d.y, d.x);\n        float a = _282;\n        float _285;\n        if (_282 < 0.0f)\n        {\n            _285 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _285 = a;\n        }\n        a = _285;\n        float _295 = _285 * 162.9746551513671875f;\n        float _304 = min((size * 10.0f) / _271, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _332 = floor(_295 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _304));\n            float param = v;\n            float param_1 = _332 - (1024.0f * floor(_332 * 0.0009765625f));\n            float _346 = shadow_texel(param, param_1) * radius;\n            if (_346 < _271)\n            {\n                sum += _346;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _378 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _271)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _396 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _402 = 1.0f - (0.800000011920928955078125f * abs(_396));\n                float param_2 = v;\n                float param_3 = _295 + (_396 * _378);\n                float param_4 = _271;\n                float param_5 = radius;\n                acc += (_402 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _402;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _142 = length(d);\n    if (_142 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _156 = atan2(d.y, d.x);\n    float a = _156;\n    float _159;\n    if (_156 < 0.0f)\n    {\n        _159 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _159 = a;\n    }\n    a = _159;\n    float _171 = _159 * 162.9746551513671875f;\n    float _176 = min(floor(_171), 1023.0f);\n    float _183 = _176 + 1.0f;\n    float i1 = _183;\n    if (_183 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _176;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _142) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _142) + 0.5f, 0.0f, 1.0f), _171 - _176);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _689 = _579_lit.y > 0.5f;\n    if (_689)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _579_normal_uv.xy) + _579_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _713 = fa_tex_fix(param, param_1);\n        float3 _717 = (_713 * 2.0f) - 1.0f.xxx;\n        float _724 = cos(params.y);\n        float _726 = sin(params.y);\n        n = normalize(float3((float2(_724, _726) * _717.x) + ((float2(-_726, _724) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _717.y), max(_717.z, 0.0500000007450580596923828125f)));\n    }\n    bool _760 = !_689;\n    bool _766;\n    if (_760)\n    {\n        _766 = _579_lit.z > 0.5f;\n    }\n    else\n    {\n        _766 = _760;\n    }\n    float3 _769;\n    if (_766)\n    {\n        _769 = _579_flat_ambient.xyz;\n    }\n    else\n    {\n        _769 = _579_ambient.xyz;\n    }\n    float3 total = _769;\n    bool _786;\n    if (_766)\n    {\n        _786 = _579_lit.z < 1.5f;\n    }\n    else\n    {\n        _786 = _766;\n    }\n    if (_786)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _579_light_map.xy, 0.0f).xyz * _579_light_map.z);\n    }\n    float3 l;\n    float _906;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _824;\n        if (!_766)\n        {\n            _824 = float(i) >= _579_lit.x;\n        }\n        else\n        {\n            _824 = _766;\n        }\n        if (_824)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_579_light_pos[i].w < 0.0f)\n        {\n            l = _579_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _850 = _579_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_850) / max(_579_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _579_light_color[i].w);\n            float3 _870 = float3(_850, _579_light_pos[i].z);\n            l = _870 / max(length(_870), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_579_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _579_light_shadow_v[i].x;\n                float param_3 = _579_light_shadow_v[i].y;\n                float2 param_4 = -_850;\n                float param_5 = _579_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_689)\n        {\n            _906 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _906 = 1.0f;\n        }\n        total += (_579_light_color[i].xyz * (att * _906));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _559 = fa_srgb_to_linear(param);\n        c = _559;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _934 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _938 = uv * _934;\n    float _944 = _934.x;\n    float _946 = _934.y;\n    float _948 = clamp(shape_rs.x, 0.0f, min(_944, _946));\n    float2 _959 = (abs(_938) - _934) + _948.xx;\n    float d = (length(max(_959, 0.0f.xx)) + min(max(_959.x, _959.y), 0.0f)) - _948;\n    float ax = params.y;\n    bool _980 = params.y > 15.0f;\n    if (_980)\n    {\n        ax -= 20.0f;\n    }\n    float _991;\n    if (ax <= (-1.5f))\n    {\n        _991 = (-2.0f) - ax;\n    }\n    else\n    {\n        _991 = 0.0f;\n    }\n    if (_991 > 0.0f)\n    {\n        float _1005 = _991 * 0.5f;\n        d = abs(d + _1005) - _1005;\n    }\n    float _1013 = fwidth(d);\n    float _1014 = max(_1013, 9.9999997473787516355514526367188e-05f);\n    float _1024 = clamp(0.5f - (d / max(shape_rs.y, _1014)), 0.0f, 1.0f);\n    float _1029;\n    if (shape_rs.y > _1014)\n    {\n        _1029 = (_1024 * _1024) * (3.0f - (2.0f * _1024));\n    }\n    else\n    {\n        _1029 = _1024;\n    }\n    float4 c = color;\n    bool _1051 = (_991 <= 0.0f) && (ax > (-0.5f));\n    if (_1051)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1066 = cos(ax);\n            float _1068 = sin(ax);\n            g = ((dot(_938, float2(_1066, _1068)) / max((abs(_1066) * _944) + (abs(_1068) * _946), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_980)\n        {\n            float4 _1111 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1111;\n            float3 param = _1111.xyz;\n            float param_1 = xform.y;\n            float3 _1118 = fa_tex_fix(param, param_1);\n            float4 _1814 = c;\n            _1814.x = _1118.x;\n            _1814.y = _1118.y;\n            _1814.z = _1118.z;\n            c = _1814;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1130 = scene_rgb(param_2);\n            float4 _1155 = lerp(float4(color.xyz * color.w, color.w), float4(_1130 * color2.w, color2.w), g.xxxx);\n            float _1157 = _1155.w;\n            float3 _1160;\n            if (_1157 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1160 = _1155.xyz / _1157.xxx;\n            }\n            else\n            {\n                _1160 = color.xyz;\n            }\n            c = float4(_1160, _1157);\n        }\n    }\n    float4 _1823 = c;\n    _1823.w = _1823.w * _1029;\n    c = _1823;\n    if (_1051 || (shape_rs.y > 0.0f))\n    {\n        float _1201 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1210 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1210 + (_1201 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1216 = fa_srgb_to_linear(param_4);\n            float4 _1826 = c;\n            _1826.x = _1216.x;\n            _1826.y = _1216.y;\n            _1826.z = _1216.z;\n            c = _1826;\n        }\n        else\n        {\n            float4 _1226 = c;\n            float3 _1229 = _1226.xyz + (_1201 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1833 = _1226;\n            _1833.x = _1229.x;\n            _1833.y = _1229.y;\n            _1833.z = _1229.z;\n            c = _1833;\n        }\n        float4 _1838 = c;\n        _1838.w = clamp(_1838.w + ((_1201 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1838.w)), 0.0f, 1.0f);\n        c = _1838;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _585 = gl_FragCoord.xy * _579_fa_target.xy;\n    float _589 = _585.y;\n    return float2(_585.x, lerp(_589, 1.0f - _589, _579_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _628 = base_mode < 0.5f;\n    bool _639;\n    if (!_628)\n    {\n        _639 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _639 = _628;\n    }\n    float _640;\n    if (_639)\n    {\n        _640 = shape_half.x;\n    }\n    else\n    {\n        _640 = 0.0f;\n    }\n    QuadInput _1787 = { uv, color, world_xy, fa_screen_uv(), _579_fa_time.x, base_mode, 0.0f.xxxx, _640 };\n    return _1787;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _565 = scene_rgb(param);\n    return _565;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _668 = fa_scene_rgb(param) * _665_boost;\n    s.color.x = _668.x;\n    s.color.y = _668.y;\n    s.color.z = _668.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1256 = params.x > 31.5f;\n    if (_1256)\n    {\n        mode -= 32.0f;\n    }\n    float _1264 = mode;\n    bool _1266 = _1264 > 15.5f;\n    if (_1266)\n    {\n        mode -= 16.0f;\n    }\n    float _1274 = mode;\n    bool _1276 = _1274 > 7.5f;\n    if (_1276)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1266)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1266)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1340 = tex_color(param_5) * color;\n                float4 param_6 = _1340;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1340.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1375 = length(uv);\n                    float _1378 = fwidth(_1375);\n                    float _1379 = max(_1378, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1375) / _1379) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1375) / _1379) + 0.5f, 0.0f, 1.0f) * clamp(((_1375 - params.y) / _1379) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1419 = clamp(1.0f - _1375, 0.0f, 1.0f);\n                            cov = (_1419 * _1419) * (3.0f - (2.0f * _1419));\n                        }\n                    }\n                    float3 _1428;\n                    if (_1266)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1428 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1428 = color.xyz;\n                    }\n                    frag_color = float4(_1428, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1767 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1769 = { _1767 };\n    QuadSurface param_12 = _1769;\n    fragment(param_11, param_12);\n    _1767 = param_12.color;\n    frag_color = param_12.color;\n    if (_1256)\n    {\n        float4 _1466 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1471 = scene_rgb(param_13);\n        float3 _1475 = lerp(_1466.xyz, _1471, color2.w.xxx);\n        frag_color.x = _1475.x;\n        frag_color.y = _1475.y;\n        frag_color.z = _1475.z;\n    }\n    if (_1276)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1499 = _579_fog_col.w > 0.0f;\n    bool _1507;\n    if (!_1499)\n    {\n        _1507 = _579_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1507 = _1499;\n    }\n    if (_1507)\n    {\n        float3 _1521 = float3(world_xy, world_z) - _579_fog_eye.xyz;\n        float _1528 = dot(_1521, _579_fog_c.xyz);\n        bool _1532 = _579_fog_c.w > 0.5f;\n        float _1533;\n        if (_1532)\n        {\n            _1533 = _1528;\n        }\n        else\n        {\n            _1533 = length(_1521);\n        }\n        float _1545 = _1533 - _579_fog_b.x;\n        if (_1545 > 0.0f)\n        {\n            float _1554 = _579_fog_col.w * _1545;\n            float tau = _1554 * _1554;\n            if (_579_fog_b.y > 0.0f)\n            {\n                float _1570;\n                if (_1532)\n                {\n                    _1570 = world_xy.y - (_579_fog_c.y * _1528);\n                }\n                else\n                {\n                    _1570 = _579_fog_eye.y;\n                }\n                float _1591 = lerp(_1570, world_xy.y, clamp(_579_fog_b.x / _1533, 0.0f, 1.0f));\n                float _1595 = world_xy.y - _1591;\n                float _1600 = _1591 - _579_fog_b.z;\n                float _1605 = world_xy.y - _579_fog_b.z;\n                bool _1608 = _1600 <= 0.0f;\n                bool _1609 = !_1608;\n                bool _1615;\n                if (_1609)\n                {\n                    _1615 = _579_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1615 = _1608;\n                }\n                float _1616;\n                if (_1615)\n                {\n                    _1616 = _579_fog_b.y;\n                }\n                else\n                {\n                    _1616 = _579_fog_b.y * exp(-min(_579_fog_b.w * _1600, 80.0f));\n                }\n                bool _1643;\n                if (_1609)\n                {\n                    _1643 = _579_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1643 = _1608;\n                }\n                float _1644;\n                if (_1643)\n                {\n                    _1644 = _579_fog_b.y * _1600;\n                }\n                else\n                {\n                    _1644 = (_579_fog_b.y * (1.0f - exp(-min(_579_fog_b.w * _1600, 80.0f)))) / _579_fog_b.w;\n                }\n                bool _1669 = _1605 <= 0.0f;\n                bool _1676;\n                if (!_1669)\n                {\n                    _1676 = _579_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1676 = _1669;\n                }\n                float _1677;\n                if (_1676)\n                {\n                    _1677 = _579_fog_b.y * _1605;\n                }\n                else\n                {\n                    _1677 = (_579_fog_b.y * (1.0f - exp(-min(_579_fog_b.w * _1605, 80.0f)))) / _579_fog_b.w;\n                }\n                float _1704;\n                if (abs(_1595) < 0.001000000047497451305389404296875f)\n                {\n                    _1704 = _1616;\n                }\n                else\n                {\n                    _1704 = (_1677 - _1644) / _1595;\n                }\n                tau += (_1545 * max(_1704, 0.0f));\n            }\n            float4 _1727 = frag_color;\n            float3 _1735 = lerp(_1727.xyz, _579_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1735.x;\n            frag_color.y = _1735.y;\n            frag_color.z = _1735.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_579",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_665",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _160_lit : packoffset(c0);\n    float4 _160_ambient : packoffset(c1);\n    float4 _160_normal_uv : packoffset(c2);\n    float4 _160_flat_ambient : packoffset(c3);\n    float4 _160_light_map : packoffset(c4);\n    float4 _160_light_pos[16] : packoffset(c5);\n    float4 _160_light_color[16] : packoffset(c21);\n    float4 _160_light_shadow_v[16] : packoffset(c37);\n    float4 _160_fog_col : packoffset(c53);\n    float4 _160_fog_b : packoffset(c54);\n    float4 _160_fog_c : packoffset(c55);\n    float4 _160_fog_eye : packoffset(c56);\n    float4 _160_fa_time : packoffset(c57);\n    float4 _160_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _252_boost : packoffset(c0);\n    float _252_fa_pad0 : packoffset(c0.y);\n    float _252_fa_pad1 : packoffset(c0.z);\n    float _252_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _167 = gl_FragCoord.xy * _160_fa_target.xy;\n    float _172 = _167.y;\n    return float2(_167.x, lerp(_172, 1.0f - _172, _160_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _215 = base_mode < 0.5f;\n    bool _226;\n    if (!_215)\n    {\n        _226 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _226 = _215;\n    }\n    float _227;\n    if (_226)\n    {\n        _227 = shape_half.x;\n    }\n    else\n    {\n        _227 = 0.0f;\n    }\n    QuadInput _365 = { uv, color, world_xy, fa_screen_uv(), _160_fa_time.x, base_mode, 0.0f.xxxx, _227 };\n    return _365;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _255 = fa_scene_rgb(param) * _252_boost;\n    s.color.x = _255.x;\n    s.color.y = _255.y;\n    s.color.z = _255.z;\n}\n\nvoid frag_main()\n{\n    float4 _282 = tex.Sample(smp, uv);\n    float3 param = _282.xyz;\n    float param_1 = xform.y;\n    float3 _291 = fa_tex_fix(param, param_1);\n    frag_color = float4(_291, _282.w) * color;\n    float param_2 = 0.0f;\n    float4 _345 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _347 = { _345 };\n    QuadSurface param_4 = _347;\n    fragment(param_3, param_4);\n    _345 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_252",
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
