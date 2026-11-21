{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _565_lit : packoffset(c0);\n    float4 _565_ambient : packoffset(c1);\n    float4 _565_normal_uv : packoffset(c2);\n    float4 _565_flat_ambient : packoffset(c3);\n    float4 _565_light_map : packoffset(c4);\n    float4 _565_light_pos[16] : packoffset(c5);\n    float4 _565_light_color[16] : packoffset(c21);\n    float4 _565_light_shadow_v[16] : packoffset(c37);\n    float4 _565_fog_col : packoffset(c53);\n    float4 _565_fog_b : packoffset(c54);\n    float4 _565_fog_c : packoffset(c55);\n    float4 _565_fog_eye : packoffset(c56);\n    float4 _565_fa_time : packoffset(c57);\n    float4 _565_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _523 = tex.Sample(smp, p);\n    float3 param = _523.xyz;\n    float param_1 = xform.y;\n    float3 _533 = fa_tex_fix(param, param_1);\n    return float4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _109 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_109.x * 255.0f) + 0.5f) * 256.0f) + floor((_109.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0f * floor(_212 * 0.0009765625f));\n    float _225 = _222 + 1.0f;\n    float i1 = _225;\n    if (_225 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0f;\n    if (_262 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _273 = atan2(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0f)\n        {\n            _276 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875f;\n        float _295 = min((size * 10.0f) / _262, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0f * floor(_323 * 0.0009765625f));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _369 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _262)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _393 = 1.0f - (0.800000011920928955078125f * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _147 = atan2(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0f)\n    {\n        _150 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875f;\n    float _167 = min(floor(_162), 1023.0f);\n    float _174 = _167 + 1.0f;\n    float i1 = _174;\n    if (_174 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5f, 0.0f, 1.0f), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _660 = _565_lit.y > 0.5f;\n    if (_660)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _565_normal_uv.xy) + _565_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _684 = fa_tex_fix(param, param_1);\n        float3 _688 = (_684 * 2.0f) - 1.0f.xxx;\n        float _695 = cos(params.y);\n        float _697 = sin(params.y);\n        n = normalize(float3((float2(_695, _697) * _688.x) + ((float2(-_697, _695) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _688.y), max(_688.z, 0.0500000007450580596923828125f)));\n    }\n    bool _730 = !_660;\n    bool _736;\n    if (_730)\n    {\n        _736 = _565_lit.z > 0.5f;\n    }\n    else\n    {\n        _736 = _730;\n    }\n    float3 _739;\n    if (_736)\n    {\n        _739 = _565_flat_ambient.xyz;\n    }\n    else\n    {\n        _739 = _565_ambient.xyz;\n    }\n    float3 total = _739;\n    bool _756;\n    if (_736)\n    {\n        _756 = _565_lit.z < 1.5f;\n    }\n    else\n    {\n        _756 = _736;\n    }\n    if (_756)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _565_light_map.xy, 0.0f).xyz * _565_light_map.z);\n    }\n    float3 l;\n    float _876;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _794;\n        if (!_736)\n        {\n            _794 = float(i) >= _565_lit.x;\n        }\n        else\n        {\n            _794 = _736;\n        }\n        if (_794)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_565_light_pos[i].w < 0.0f)\n        {\n            l = _565_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _820 = _565_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_820) / max(_565_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _565_light_color[i].w);\n            float3 _840 = float3(_820, _565_light_pos[i].z);\n            l = _840 / max(length(_840), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_565_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _565_light_shadow_v[i].x;\n                float param_3 = _565_light_shadow_v[i].y;\n                float2 param_4 = -_820;\n                float param_5 = _565_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_660)\n        {\n            _876 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _876 = 1.0f;\n        }\n        total += (_565_light_color[i].xyz * (att * _876));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _904 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _908 = uv * _904;\n    float _914 = _904.x;\n    float _916 = _904.y;\n    float _918 = clamp(shape_rs.x, 0.0f, min(_914, _916));\n    float2 _929 = (abs(_908) - _904) + _918.xx;\n    float d = (length(max(_929, 0.0f.xx)) + min(max(_929.x, _929.y), 0.0f)) - _918;\n    float ax = params.y;\n    bool _950 = params.y > 15.0f;\n    if (_950)\n    {\n        ax -= 20.0f;\n    }\n    float _961;\n    if (ax <= (-1.5f))\n    {\n        _961 = (-2.0f) - ax;\n    }\n    else\n    {\n        _961 = 0.0f;\n    }\n    if (_961 > 0.0f)\n    {\n        float _975 = _961 * 0.5f;\n        d = abs(d + _975) - _975;\n    }\n    float _983 = fwidth(d);\n    float _984 = max(_983, 9.9999997473787516355514526367188e-05f);\n    float _994 = clamp(0.5f - (d / max(shape_rs.y, _984)), 0.0f, 1.0f);\n    float _999;\n    if (shape_rs.y > _984)\n    {\n        _999 = (_994 * _994) * (3.0f - (2.0f * _994));\n    }\n    else\n    {\n        _999 = _994;\n    }\n    float4 c = color;\n    bool _1021 = (_961 <= 0.0f) && (ax > (-0.5f));\n    if (_1021)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1036 = cos(ax);\n            float _1038 = sin(ax);\n            g = ((dot(_908, float2(_1036, _1038)) / max((abs(_1036) * _914) + (abs(_1038) * _916), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_950)\n        {\n            float4 _1081 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1081;\n            float3 param = _1081.xyz;\n            float param_1 = xform.y;\n            float3 _1088 = fa_tex_fix(param, param_1);\n            float4 _1784 = c;\n            _1784.x = _1088.x;\n            _1784.y = _1088.y;\n            _1784.z = _1088.z;\n            c = _1784;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1100 = scene_rgb(param_2);\n            float4 _1125 = lerp(float4(color.xyz * color.w, color.w), float4(_1100 * color2.w, color2.w), g.xxxx);\n            float _1127 = _1125.w;\n            float3 _1130;\n            if (_1127 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1130 = _1125.xyz / _1127.xxx;\n            }\n            else\n            {\n                _1130 = color.xyz;\n            }\n            c = float4(_1130, _1127);\n        }\n    }\n    float4 _1793 = c;\n    _1793.w = _1793.w * _999;\n    c = _1793;\n    if (_1021 || (shape_rs.y > 0.0f))\n    {\n        float _1171 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1180 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1180 + (_1171 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1186 = fa_srgb_to_linear(param_4);\n            float4 _1796 = c;\n            _1796.x = _1186.x;\n            _1796.y = _1186.y;\n            _1796.z = _1186.z;\n            c = _1796;\n        }\n        else\n        {\n            float4 _1196 = c;\n            float3 _1199 = _1196.xyz + (_1171 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1803 = _1196;\n            _1803.x = _1199.x;\n            _1803.y = _1199.y;\n            _1803.z = _1199.z;\n            c = _1803;\n        }\n        float4 _1808 = c;\n        _1808.w = clamp(_1808.w + ((_1171 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1808.w)), 0.0f, 1.0f);\n        c = _1808;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _571 = gl_FragCoord.xy * _565_fa_target.xy;\n    float _575 = _571.y;\n    return float2(_571.x, lerp(_575, 1.0f - _575, _565_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5f;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0f;\n    }\n    QuadInput _1757 = { uv, color, world_xy, fa_screen_uv(), _565_fa_time.x, base_mode, 0.0f.xxxx, _626 };\n    return _1757;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _646 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _646.x;\n    s.color.y = _646.y;\n    s.color.z = _646.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1226 = params.x > 31.5f;\n    if (_1226)\n    {\n        mode -= 32.0f;\n    }\n    float _1234 = mode;\n    bool _1236 = _1234 > 15.5f;\n    if (_1236)\n    {\n        mode -= 16.0f;\n    }\n    float _1244 = mode;\n    bool _1246 = _1244 > 7.5f;\n    if (_1246)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1236)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1236)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1310 = tex_color(param_5) * color;\n                float4 param_6 = _1310;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1310.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1345 = length(uv);\n                    float _1348 = fwidth(_1345);\n                    float _1349 = max(_1348, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1345) / _1349) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1345) / _1349) + 0.5f, 0.0f, 1.0f) * clamp(((_1345 - params.y) / _1349) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1389 = clamp(1.0f - _1345, 0.0f, 1.0f);\n                            cov = (_1389 * _1389) * (3.0f - (2.0f * _1389));\n                        }\n                    }\n                    float3 _1398;\n                    if (_1236)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1398 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1398 = color.xyz;\n                    }\n                    frag_color = float4(_1398, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1737 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1739 = { _1737 };\n    QuadSurface param_12 = _1739;\n    fragment(param_11, param_12);\n    _1737 = param_12.color;\n    frag_color = param_12.color;\n    if (_1226)\n    {\n        float4 _1436 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1441 = scene_rgb(param_13);\n        float3 _1445 = lerp(_1436.xyz, _1441, color2.w.xxx);\n        frag_color.x = _1445.x;\n        frag_color.y = _1445.y;\n        frag_color.z = _1445.z;\n    }\n    if (_1246)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1469 = _565_fog_col.w > 0.0f;\n    bool _1477;\n    if (!_1469)\n    {\n        _1477 = _565_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1477 = _1469;\n    }\n    if (_1477)\n    {\n        float3 _1491 = float3(world_xy, world_z) - _565_fog_eye.xyz;\n        float _1498 = dot(_1491, _565_fog_c.xyz);\n        bool _1502 = _565_fog_c.w > 0.5f;\n        float _1503;\n        if (_1502)\n        {\n            _1503 = _1498;\n        }\n        else\n        {\n            _1503 = length(_1491);\n        }\n        float _1515 = _1503 - _565_fog_b.x;\n        if (_1515 > 0.0f)\n        {\n            float _1524 = _565_fog_col.w * _1515;\n            float tau = _1524 * _1524;\n            if (_565_fog_b.y > 0.0f)\n            {\n                float _1540;\n                if (_1502)\n                {\n                    _1540 = world_xy.y - (_565_fog_c.y * _1498);\n                }\n                else\n                {\n                    _1540 = _565_fog_eye.y;\n                }\n                float _1561 = lerp(_1540, world_xy.y, clamp(_565_fog_b.x / _1503, 0.0f, 1.0f));\n                float _1565 = world_xy.y - _1561;\n                float _1570 = _1561 - _565_fog_b.z;\n                float _1575 = world_xy.y - _565_fog_b.z;\n                bool _1578 = _1570 <= 0.0f;\n                bool _1579 = !_1578;\n                bool _1585;\n                if (_1579)\n                {\n                    _1585 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1585 = _1578;\n                }\n                float _1586;\n                if (_1585)\n                {\n                    _1586 = _565_fog_b.y;\n                }\n                else\n                {\n                    _1586 = _565_fog_b.y * exp(-min(_565_fog_b.w * _1570, 80.0f));\n                }\n                bool _1613;\n                if (_1579)\n                {\n                    _1613 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1613 = _1578;\n                }\n                float _1614;\n                if (_1613)\n                {\n                    _1614 = _565_fog_b.y * _1570;\n                }\n                else\n                {\n                    _1614 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1570, 80.0f)))) / _565_fog_b.w;\n                }\n                bool _1639 = _1575 <= 0.0f;\n                bool _1646;\n                if (!_1639)\n                {\n                    _1646 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1646 = _1639;\n                }\n                float _1647;\n                if (_1646)\n                {\n                    _1647 = _565_fog_b.y * _1575;\n                }\n                else\n                {\n                    _1647 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1575, 80.0f)))) / _565_fog_b.w;\n                }\n                float _1674;\n                if (abs(_1565) < 0.001000000047497451305389404296875f)\n                {\n                    _1674 = _1586;\n                }\n                else\n                {\n                    _1674 = (_1647 - _1614) / _1565;\n                }\n                tau += (_1515 * max(_1674, 0.0f));\n            }\n            float4 _1697 = frag_color;\n            float3 _1705 = lerp(_1697.xyz, _565_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1705.x;\n            frag_color.y = _1705.y;\n            frag_color.z = _1705.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_96",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_565",
            "hlsl_register_b_n": 1
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _127_lit : packoffset(c0);\n    float4 _127_ambient : packoffset(c1);\n    float4 _127_normal_uv : packoffset(c2);\n    float4 _127_flat_ambient : packoffset(c3);\n    float4 _127_light_map : packoffset(c4);\n    float4 _127_light_pos[16] : packoffset(c5);\n    float4 _127_light_color[16] : packoffset(c21);\n    float4 _127_light_shadow_v[16] : packoffset(c37);\n    float4 _127_fog_col : packoffset(c53);\n    float4 _127_fog_b : packoffset(c54);\n    float4 _127_fog_c : packoffset(c55);\n    float4 _127_fog_eye : packoffset(c56);\n    float4 _127_fa_time : packoffset(c57);\n    float4 _127_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _134 = gl_FragCoord.xy * _127_fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, lerp(_140, 1.0f - _140, _127_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5f;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0f;\n    }\n    QuadInput _322 = { uv, color, world_xy, fa_screen_uv(), _127_fa_time.x, base_mode, 0.0f.xxxx, _196 };\n    return _322;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _222 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _222.x;\n    s.color.y = _222.y;\n    s.color.z = _222.z;\n}\n\nvoid frag_main()\n{\n    float4 _237 = tex.Sample(smp, uv);\n    float3 param = _237.xyz;\n    float param_1 = xform.y;\n    float3 _248 = fa_tex_fix(param, param_1);\n    frag_color = float4(_248, _237.w) * color;\n    float param_2 = 0.0f;\n    float4 _302 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _304 = { _302 };\n    QuadSurface param_4 = _304;\n    fragment(param_3, param_4);\n    _302 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_96",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 1
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    }
  }
}
