{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ec571f7df6ebcd6b8e540d92ba5bb2b19c6b0b33ef134d5541e8df34e8adf190",
  "slang": "hlsl5",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n    float4 _129_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _109 = fa_world_position(param);\n    v_pos = _109;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_109, 1.0f), _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _317_fa_shadow_mat[4] : packoffset(c0);\n    float4 _317_fa_shadow_rect[4] : packoffset(c16);\n    float4 _317_fa_shadow_info[4] : packoffset(c20);\n    float4 _317_fa_shadow_split : packoffset(c24);\n    float4 _317_fa_shadow_cfg : packoffset(c25);\n    float4 _317_fa_shadow_bias : packoffset(c26);\n    float4 _317_fa_shadow_eye : packoffset(c27);\n    float4 _317_fa_shadow_fwd : packoffset(c28);\n    float4 _317_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _730_fa_camera_pos : packoffset(c0);\n    float4 _730_fa_ambient : packoffset(c1);\n    float4 _730_fa_base_color : packoffset(c2);\n    float4 _730_fa_emissive : packoffset(c3);\n    float4 _730_fa_model_emissive : packoffset(c4);\n    float4 _730_fa_pbr : packoffset(c5);\n    float4 _730_fa_maps : packoffset(c6);\n    float4 _730_fa_fog : packoffset(c7);\n    float4 _730_fa_fog_b : packoffset(c8);\n    float4 _730_fa_fog_c : packoffset(c9);\n    float4 _730_fa_counts : packoffset(c10);\n    float4 _730_fa_env_sky : packoffset(c11);\n    float4 _730_fa_env_horizon : packoffset(c12);\n    float4 _730_fa_time : packoffset(c13);\n    float4 _730_fa_cl_vpx : packoffset(c14);\n    float4 _730_fa_cl_vpy : packoffset(c15);\n    float4 _730_fa_cl_vpw : packoffset(c16);\n    float4 _730_fa_cl_fwd : packoffset(c17);\n    float4 _730_fa_cl_grid : packoffset(c18);\n    float4 _730_fa_cl_info : packoffset(c19);\n    float4 _730_fa_layers_a : packoffset(c20);\n    float4 _730_fa_layers_b : packoffset(c21);\n    float4 _730_fa_layers_c : packoffset(c22);\n    float4 _730_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1602_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_730_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _135 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _142 = fa_light_texel(param_1);\n    float _147 = _142.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _155 = _147 < 0.5f;\n    float3 l;\n    if (_155)\n    {\n        l = normalize(_135.xyz);\n    }\n    else\n    {\n        float3 _167 = _135.xyz - world_pos;\n        float _169 = length(_167);\n        dist = _169;\n        l = _167 / max(_169, 9.9999997473787516355514526367188e-05f).xxx;\n        float _184 = _169 / max(_135.w, 0.001000000047497451305389404296875f);\n        float _190 = clamp(1.0f - (_184 * _184), 0.0f, 1.0f);\n        atten = _190 * _190;\n        if (_147 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _205 = fa_light_texel(param_2);\n            float _215 = _205.w;\n            int param_3 = (li * 4) + 3;\n            float4 _222 = fa_light_texel(param_3);\n            float _224 = _222.x;\n            float cos_inner = _224;\n            if (_224 > 1.5f)\n            {\n                cos_inner = lerp(_215, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_215, cos_inner, dot(-l, normalize(_205.xyz)));\n        }\n    }\n    int _255;\n    if (_155)\n    {\n        _255 = 0;\n    }\n    else\n    {\n        _255 = (_147 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1676 = { l, _142.xyz * atten, atten, 1.0f, dist, _255 };\n    return _1676;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _307;\n    if (i == 0)\n    {\n        _307 = _317_fa_shadow_split.x;\n    }\n    else\n    {\n        float _324;\n        if (i == 1)\n        {\n            _324 = _317_fa_shadow_split.y;\n        }\n        else\n        {\n            float _333;\n            if (i == 2)\n            {\n                _333 = _317_fa_shadow_split.z;\n            }\n            else\n            {\n                _333 = _317_fa_shadow_split.w;\n            }\n            _324 = _333;\n        }\n        _307 = _324;\n    }\n    return _307;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _367 = fa_shadow_depth(param, param_1);\n    float _371;\n    if (conv.x < 0.5f)\n    {\n        _371 = _367;\n    }\n    else\n    {\n        _371 = (conv.y * conv.z) / (conv.z - (_367 * (conv.z - conv.y)));\n    }\n    return _371;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _295 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_295), sin(_295)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _418 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _432 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _418;\n            float2 _452 = fa_shadow_vogel(param_3, param_4, param_5) * _432;\n            float2 param_6 = uv + (_452 * _317_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _464 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_464 < (zr - (length(_452) * plane)))\n            {\n                sum += _464;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _508 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _508; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _508;\n        float param_11 = _418;\n        float2 _527 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_527 * _317_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_527) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_508);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _569 = max(_317_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _574 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _580 = sqrt(1.0f - (_574 * _574));\n    float _588 = min(_580 / max(_574, 0.20000000298023223876953125f), 4.0f);\n    float _593;\n    if (_317_fa_shadow_bias.y > 0.0f)\n    {\n        _593 = _317_fa_shadow_bias.y;\n    }\n    else\n    {\n        _593 = 1.5f * _317_fa_shadow_info[ci].x;\n    }\n    float4 _618 = mul(float4(world + (n * (_593 * _580)), 1.0f), _317_fa_shadow_mat[ci]);\n    float _625 = _618.x;\n    bool _628 = _625 < _317_fa_shadow_rect[ci].x;\n    bool _637;\n    if (!_628)\n    {\n        _637 = _625 > _317_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _637 = _628;\n    }\n    bool _646;\n    if (!_637)\n    {\n        _646 = _618.y < _317_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _646 = _637;\n    }\n    bool _655;\n    if (!_646)\n    {\n        _655 = _618.y > _317_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _655 = _646;\n    }\n    bool _662;\n    if (!_655)\n    {\n        _662 = _618.z > 1.0f;\n    }\n    else\n    {\n        _662 = _655;\n    }\n    if (_662)\n    {\n        return -1.0f;\n    }\n    float _671;\n    if (_317_fa_shadow_bias.x > 0.0f)\n    {\n        _671 = _317_fa_shadow_bias.x;\n    }\n    else\n    {\n        _671 = 1.5f * _317_fa_shadow_info[ci].x;\n    }\n    float2 param = _618.xy;\n    float4 param_1 = _317_fa_shadow_rect[ci];\n    float param_2 = _618.z - ((_671 * (1.0f + (0.5f * _588))) / _569);\n    float param_3 = _317_fa_shadow_info[ci].x;\n    float param_4 = _569;\n    float param_5 = _569 * 0.25f;\n    float param_6 = ((_317_fa_shadow_info[ci].x * min(_588, 3.0f)) * 0.5f) / _569;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_317_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _317_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_730_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1103 = int(_317_fa_shadow_cfg.x + 0.5f);\n    if (_1103 < 1)\n    {\n        return 1.0f;\n    }\n    float _1119 = dot(world - _317_fa_shadow_eye.xyz, _317_fa_shadow_fwd.xyz);\n    int param = _1103 - 1;\n    if (_1119 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1131 = _1103 > 1;\n    bool _1138;\n    if (_1131)\n    {\n        _1138 = _1119 > _317_fa_shadow_split.x;\n    }\n    else\n    {\n        _1138 = _1131;\n    }\n    if (_1138)\n    {\n        ci = 1;\n    }\n    bool _1142 = _1103 > 2;\n    bool _1149;\n    if (_1142)\n    {\n        _1149 = _1119 > _317_fa_shadow_split.y;\n    }\n    else\n    {\n        _1149 = _1142;\n    }\n    if (_1149)\n    {\n        ci = 2;\n    }\n    bool _1153 = _1103 > 3;\n    bool _1160;\n    if (_1153)\n    {\n        _1160 = _1119 > _317_fa_shadow_split.z;\n    }\n    else\n    {\n        _1160 = _1153;\n    }\n    if (_1160)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1103)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1186 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1186;\n        if (_1186 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_317_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1211;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1211 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1211 = _317_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1230 = _317_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1211, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1241 = clamp((_1119 - (fa_shadow_split_at(param_7) - _1230)) / _1230, 0.0f, 1.0f);\n        if (_1241 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1103)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1262 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1262;\n                if (_1262 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1241);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _733 = _730_fa_pbr.z < 0.5f;\n    bool _741;\n    if (!_733)\n    {\n        _741 = _317_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _741 = _733;\n    }\n    if (_741)\n    {\n        return 1.0f;\n    }\n    int param = (int(_317_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _754 = fa_light_texel(param);\n    float _755 = _754.x;\n    if (_755 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _764 = int(_755 + 0.5f);\n    int param_1 = _764;\n    float4 _768 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    float4 _773 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _776 = _768.y;\n    if (_776 > 0.0f)\n    {\n        float _794 = 1.0f - smoothstep(0.75f * _776, _776, length(world - _317_fa_shadow_eye.xyz));\n        fade = _794;\n        if (_794 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_768.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _813 = world - fa_light_texel(param_3).xyz;\n        float3 _816 = abs(_813);\n        float _818 = _816.x;\n        float _820 = _816.y;\n        bool _821 = _818 >= _820;\n        bool _829;\n        if (_821)\n        {\n            _829 = _818 >= _816.z;\n        }\n        else\n        {\n            _829 = _821;\n        }\n        int _830;\n        if (_829)\n        {\n            _830 = (_813.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _843;\n            if (_820 >= _816.z)\n            {\n                _843 = (_813.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _843 = (_813.z > 0.0f) ? 4 : 5;\n            }\n            _830 = _843;\n        }\n        face = _830;\n    }\n    int _862 = (_764 + 2) + (face * 6);\n    int param_4 = _862;\n    int param_5 = _862 + 1;\n    int param_6 = _862 + 3;\n    float4 _876 = fa_light_texel(param_6);\n    int param_7 = _862 + 4;\n    float4 _881 = fa_light_texel(param_7);\n    int param_8 = _862 + 5;\n    float4 _886 = fa_light_texel(param_8);\n    float _898 = _886.x * max(dot(_876, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _903 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _926 = clamp(dot(n, _876.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _949 = min(sqrt(1.0f - (_926 * _926)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_876, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _952 = _773.y;\n    float _954;\n    if (_952 > 0.0f)\n    {\n        _954 = _952;\n    }\n    else\n    {\n        _954 = 1.5f * _898;\n    }\n    float4 _974 = float4(world + (n * (_954 * sqrt(1.0f - (_903 * _903)))), 1.0f);\n    float _978 = dot(_876, _974);\n    float _981 = _886.y;\n    if (_978 < _981)\n    {\n        return 1.0f;\n    }\n    float2 _996 = float2(dot(fa_light_texel(param_4), _974), dot(fa_light_texel(param_5), _974)) / _978.xx;\n    float _998 = _996.x;\n    bool _1001 = _998 < _881.x;\n    bool _1010;\n    if (!_1001)\n    {\n        _1010 = _998 > _881.z;\n    }\n    else\n    {\n        _1010 = _1001;\n    }\n    bool _1019;\n    if (!_1010)\n    {\n        _1019 = _996.y < _881.y;\n    }\n    else\n    {\n        _1019 = _1010;\n    }\n    bool _1028;\n    if (!_1019)\n    {\n        _1028 = _996.y > _881.w;\n    }\n    else\n    {\n        _1028 = _1019;\n    }\n    if (_1028)\n    {\n        return 1.0f;\n    }\n    float _1034 = _773.x;\n    float _1036;\n    if (_1034 > 0.0f)\n    {\n        _1036 = _1034;\n    }\n    else\n    {\n        _1036 = 1.5f * _898;\n    }\n    float2 param_10 = _996;\n    float4 param_11 = _881;\n    float param_12 = _978 - (_1036 * (1.0f + (0.5f * _949)));\n    float param_13 = _898;\n    float param_14 = 1.0f;\n    float param_15 = _886.z * 0.25f;\n    float param_16 = (_898 * min(_949, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _981, _886.z);\n    int param_18 = int(_768.z + 0.5f);\n    float param_19 = _768.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1301 = fa_light_sample(param, param_1);\n    float3 _1683 = _1301.direction;\n    float3 _1678 = _1301.color;\n    float _1685 = _1301.attenuation;\n    float _1680 = _1301.shadow;\n    int _1688 = _1301.type;\n    if ((_1688 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1683;\n        float _1317 = fa_shadow(param_2, param_3, param_4);\n        _1680 = _1317;\n        _1678 *= _1317;\n    }\n    else\n    {\n        bool _1328 = _1688 != 0;\n        bool _1334;\n        if (_1328)\n        {\n            _1334 = _1685 > 0.0f;\n        }\n        else\n        {\n            _1334 = _1328;\n        }\n        if (_1334)\n        {\n            int param_5 = li;\n            float3 param_6 = world_pos;\n            float3 param_7 = gn;\n            float3 param_8 = _1683;\n            float _1346 = fa_shadow_local(param_5, param_6, param_7, param_8);\n            _1680 = _1346;\n            _1678 *= _1346;\n        }\n    }\n    LightSample _1695 = { _1683, _1678, _1685, _1680, _1301._distance, _1688 };\n    return _1695;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _1359 = _730_fa_fog.w > 0.0f;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _730_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    if (_1366)\n    {\n        float3 _1374 = world_pos - _730_fa_camera_pos.xyz;\n        float _1381 = dot(_1374, _730_fa_fog_c.xyz);\n        bool _1385 = _730_fa_fog_c.w > 0.5f;\n        float _1386;\n        if (_1385)\n        {\n            _1386 = _1381;\n        }\n        else\n        {\n            _1386 = length(_1374);\n        }\n        float _1398 = _1386 - _730_fa_fog_b.x;\n        if (_1398 > 0.0f)\n        {\n            float _1407 = _730_fa_fog.w * _1398;\n            float tau = _1407 * _1407;\n            if (_730_fa_fog_b.y > 0.0f)\n            {\n                float _1423;\n                if (_1385)\n                {\n                    _1423 = world_pos.y - (_730_fa_fog_c.y * _1381);\n                }\n                else\n                {\n                    _1423 = _730_fa_camera_pos.y;\n                }\n                float _1444 = lerp(_1423, world_pos.y, clamp(_730_fa_fog_b.x / _1386, 0.0f, 1.0f));\n                float _1448 = world_pos.y - _1444;\n                float _1453 = _1444 - _730_fa_fog_b.z;\n                float _1458 = world_pos.y - _730_fa_fog_b.z;\n                bool _1461 = _1453 <= 0.0f;\n                bool _1462 = !_1461;\n                bool _1468;\n                if (_1462)\n                {\n                    _1468 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1468 = _1461;\n                }\n                float _1469;\n                if (_1468)\n                {\n                    _1469 = _730_fa_fog_b.y;\n                }\n                else\n                {\n                    _1469 = _730_fa_fog_b.y * exp(-min(_730_fa_fog_b.w * _1453, 80.0f));\n                }\n                bool _1496;\n                if (_1462)\n                {\n                    _1496 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1496 = _1461;\n                }\n                float _1497;\n                if (_1496)\n                {\n                    _1497 = _730_fa_fog_b.y * _1453;\n                }\n                else\n                {\n                    _1497 = (_730_fa_fog_b.y * (1.0f - exp(-min(_730_fa_fog_b.w * _1453, 80.0f)))) / _730_fa_fog_b.w;\n                }\n                bool _1522 = _1458 <= 0.0f;\n                bool _1529;\n                if (!_1522)\n                {\n                    _1529 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1529 = _1522;\n                }\n                float _1530;\n                if (_1529)\n                {\n                    _1530 = _730_fa_fog_b.y * _1458;\n                }\n                else\n                {\n                    _1530 = (_730_fa_fog_b.y * (1.0f - exp(-min(_730_fa_fog_b.w * _1458, 80.0f)))) / _730_fa_fog_b.w;\n                }\n                float _1557;\n                if (abs(_1448) < 0.001000000047497451305389404296875f)\n                {\n                    _1557 = _1469;\n                }\n                else\n                {\n                    _1557 = (_1530 - _1497) / _1448;\n                }\n                tau += (_1398 * max(_1557, 0.0f));\n            }\n            result = lerp(result, _730_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1595 = normalize(v_normal);\n    float3 lit = _730_fa_ambient.xyz * _1602_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1595;\n        float4 param_3 = v_shadow;\n        LightSample _1627 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1602_base.xyz * _1627.color) * max(dot(_1595, _1627.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1650 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1650, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_317",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_730",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1602",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _71_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _247_fa_view_proj : packoffset(c0);\n    row_major float4x4 _247_fa_light_vp : packoffset(c4);\n    float4 _247_fa_uv_scale : packoffset(c8);\n    float4 _247_fa_time : packoffset(c9);\n    float4 _247_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_71_fa_joint_rows[_61] * weights[i]);\n        r1 += (_71_fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71_fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _227 = fa_world_position(param);\n    v_pos = _227;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_227, 1.0f), _247_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _317_fa_shadow_mat[4] : packoffset(c0);\n    float4 _317_fa_shadow_rect[4] : packoffset(c16);\n    float4 _317_fa_shadow_info[4] : packoffset(c20);\n    float4 _317_fa_shadow_split : packoffset(c24);\n    float4 _317_fa_shadow_cfg : packoffset(c25);\n    float4 _317_fa_shadow_bias : packoffset(c26);\n    float4 _317_fa_shadow_eye : packoffset(c27);\n    float4 _317_fa_shadow_fwd : packoffset(c28);\n    float4 _317_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _730_fa_camera_pos : packoffset(c0);\n    float4 _730_fa_ambient : packoffset(c1);\n    float4 _730_fa_base_color : packoffset(c2);\n    float4 _730_fa_emissive : packoffset(c3);\n    float4 _730_fa_model_emissive : packoffset(c4);\n    float4 _730_fa_pbr : packoffset(c5);\n    float4 _730_fa_maps : packoffset(c6);\n    float4 _730_fa_fog : packoffset(c7);\n    float4 _730_fa_fog_b : packoffset(c8);\n    float4 _730_fa_fog_c : packoffset(c9);\n    float4 _730_fa_counts : packoffset(c10);\n    float4 _730_fa_env_sky : packoffset(c11);\n    float4 _730_fa_env_horizon : packoffset(c12);\n    float4 _730_fa_time : packoffset(c13);\n    float4 _730_fa_cl_vpx : packoffset(c14);\n    float4 _730_fa_cl_vpy : packoffset(c15);\n    float4 _730_fa_cl_vpw : packoffset(c16);\n    float4 _730_fa_cl_fwd : packoffset(c17);\n    float4 _730_fa_cl_grid : packoffset(c18);\n    float4 _730_fa_cl_info : packoffset(c19);\n    float4 _730_fa_layers_a : packoffset(c20);\n    float4 _730_fa_layers_b : packoffset(c21);\n    float4 _730_fa_layers_c : packoffset(c22);\n    float4 _730_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1602_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_730_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _135 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _142 = fa_light_texel(param_1);\n    float _147 = _142.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _155 = _147 < 0.5f;\n    float3 l;\n    if (_155)\n    {\n        l = normalize(_135.xyz);\n    }\n    else\n    {\n        float3 _167 = _135.xyz - world_pos;\n        float _169 = length(_167);\n        dist = _169;\n        l = _167 / max(_169, 9.9999997473787516355514526367188e-05f).xxx;\n        float _184 = _169 / max(_135.w, 0.001000000047497451305389404296875f);\n        float _190 = clamp(1.0f - (_184 * _184), 0.0f, 1.0f);\n        atten = _190 * _190;\n        if (_147 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _205 = fa_light_texel(param_2);\n            float _215 = _205.w;\n            int param_3 = (li * 4) + 3;\n            float4 _222 = fa_light_texel(param_3);\n            float _224 = _222.x;\n            float cos_inner = _224;\n            if (_224 > 1.5f)\n            {\n                cos_inner = lerp(_215, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_215, cos_inner, dot(-l, normalize(_205.xyz)));\n        }\n    }\n    int _255;\n    if (_155)\n    {\n        _255 = 0;\n    }\n    else\n    {\n        _255 = (_147 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1676 = { l, _142.xyz * atten, atten, 1.0f, dist, _255 };\n    return _1676;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _307;\n    if (i == 0)\n    {\n        _307 = _317_fa_shadow_split.x;\n    }\n    else\n    {\n        float _324;\n        if (i == 1)\n        {\n            _324 = _317_fa_shadow_split.y;\n        }\n        else\n        {\n            float _333;\n            if (i == 2)\n            {\n                _333 = _317_fa_shadow_split.z;\n            }\n            else\n            {\n                _333 = _317_fa_shadow_split.w;\n            }\n            _324 = _333;\n        }\n        _307 = _324;\n    }\n    return _307;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _367 = fa_shadow_depth(param, param_1);\n    float _371;\n    if (conv.x < 0.5f)\n    {\n        _371 = _367;\n    }\n    else\n    {\n        _371 = (conv.y * conv.z) / (conv.z - (_367 * (conv.z - conv.y)));\n    }\n    return _371;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _295 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_295), sin(_295)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _418 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _432 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _418;\n            float2 _452 = fa_shadow_vogel(param_3, param_4, param_5) * _432;\n            float2 param_6 = uv + (_452 * _317_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _464 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_464 < (zr - (length(_452) * plane)))\n            {\n                sum += _464;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _508 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _508; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _508;\n        float param_11 = _418;\n        float2 _527 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_527 * _317_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_527) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_508);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _569 = max(_317_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _574 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _580 = sqrt(1.0f - (_574 * _574));\n    float _588 = min(_580 / max(_574, 0.20000000298023223876953125f), 4.0f);\n    float _593;\n    if (_317_fa_shadow_bias.y > 0.0f)\n    {\n        _593 = _317_fa_shadow_bias.y;\n    }\n    else\n    {\n        _593 = 1.5f * _317_fa_shadow_info[ci].x;\n    }\n    float4 _618 = mul(float4(world + (n * (_593 * _580)), 1.0f), _317_fa_shadow_mat[ci]);\n    float _625 = _618.x;\n    bool _628 = _625 < _317_fa_shadow_rect[ci].x;\n    bool _637;\n    if (!_628)\n    {\n        _637 = _625 > _317_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _637 = _628;\n    }\n    bool _646;\n    if (!_637)\n    {\n        _646 = _618.y < _317_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _646 = _637;\n    }\n    bool _655;\n    if (!_646)\n    {\n        _655 = _618.y > _317_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _655 = _646;\n    }\n    bool _662;\n    if (!_655)\n    {\n        _662 = _618.z > 1.0f;\n    }\n    else\n    {\n        _662 = _655;\n    }\n    if (_662)\n    {\n        return -1.0f;\n    }\n    float _671;\n    if (_317_fa_shadow_bias.x > 0.0f)\n    {\n        _671 = _317_fa_shadow_bias.x;\n    }\n    else\n    {\n        _671 = 1.5f * _317_fa_shadow_info[ci].x;\n    }\n    float2 param = _618.xy;\n    float4 param_1 = _317_fa_shadow_rect[ci];\n    float param_2 = _618.z - ((_671 * (1.0f + (0.5f * _588))) / _569);\n    float param_3 = _317_fa_shadow_info[ci].x;\n    float param_4 = _569;\n    float param_5 = _569 * 0.25f;\n    float param_6 = ((_317_fa_shadow_info[ci].x * min(_588, 3.0f)) * 0.5f) / _569;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_317_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _317_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_730_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1103 = int(_317_fa_shadow_cfg.x + 0.5f);\n    if (_1103 < 1)\n    {\n        return 1.0f;\n    }\n    float _1119 = dot(world - _317_fa_shadow_eye.xyz, _317_fa_shadow_fwd.xyz);\n    int param = _1103 - 1;\n    if (_1119 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1131 = _1103 > 1;\n    bool _1138;\n    if (_1131)\n    {\n        _1138 = _1119 > _317_fa_shadow_split.x;\n    }\n    else\n    {\n        _1138 = _1131;\n    }\n    if (_1138)\n    {\n        ci = 1;\n    }\n    bool _1142 = _1103 > 2;\n    bool _1149;\n    if (_1142)\n    {\n        _1149 = _1119 > _317_fa_shadow_split.y;\n    }\n    else\n    {\n        _1149 = _1142;\n    }\n    if (_1149)\n    {\n        ci = 2;\n    }\n    bool _1153 = _1103 > 3;\n    bool _1160;\n    if (_1153)\n    {\n        _1160 = _1119 > _317_fa_shadow_split.z;\n    }\n    else\n    {\n        _1160 = _1153;\n    }\n    if (_1160)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1103)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1186 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1186;\n        if (_1186 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_317_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1211;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1211 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1211 = _317_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1230 = _317_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1211, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1241 = clamp((_1119 - (fa_shadow_split_at(param_7) - _1230)) / _1230, 0.0f, 1.0f);\n        if (_1241 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1103)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1262 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1262;\n                if (_1262 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1241);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _733 = _730_fa_pbr.z < 0.5f;\n    bool _741;\n    if (!_733)\n    {\n        _741 = _317_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _741 = _733;\n    }\n    if (_741)\n    {\n        return 1.0f;\n    }\n    int param = (int(_317_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _754 = fa_light_texel(param);\n    float _755 = _754.x;\n    if (_755 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _764 = int(_755 + 0.5f);\n    int param_1 = _764;\n    float4 _768 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    float4 _773 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _776 = _768.y;\n    if (_776 > 0.0f)\n    {\n        float _794 = 1.0f - smoothstep(0.75f * _776, _776, length(world - _317_fa_shadow_eye.xyz));\n        fade = _794;\n        if (_794 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_768.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _813 = world - fa_light_texel(param_3).xyz;\n        float3 _816 = abs(_813);\n        float _818 = _816.x;\n        float _820 = _816.y;\n        bool _821 = _818 >= _820;\n        bool _829;\n        if (_821)\n        {\n            _829 = _818 >= _816.z;\n        }\n        else\n        {\n            _829 = _821;\n        }\n        int _830;\n        if (_829)\n        {\n            _830 = (_813.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _843;\n            if (_820 >= _816.z)\n            {\n                _843 = (_813.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _843 = (_813.z > 0.0f) ? 4 : 5;\n            }\n            _830 = _843;\n        }\n        face = _830;\n    }\n    int _862 = (_764 + 2) + (face * 6);\n    int param_4 = _862;\n    int param_5 = _862 + 1;\n    int param_6 = _862 + 3;\n    float4 _876 = fa_light_texel(param_6);\n    int param_7 = _862 + 4;\n    float4 _881 = fa_light_texel(param_7);\n    int param_8 = _862 + 5;\n    float4 _886 = fa_light_texel(param_8);\n    float _898 = _886.x * max(dot(_876, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _903 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _926 = clamp(dot(n, _876.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _949 = min(sqrt(1.0f - (_926 * _926)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_876, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _952 = _773.y;\n    float _954;\n    if (_952 > 0.0f)\n    {\n        _954 = _952;\n    }\n    else\n    {\n        _954 = 1.5f * _898;\n    }\n    float4 _974 = float4(world + (n * (_954 * sqrt(1.0f - (_903 * _903)))), 1.0f);\n    float _978 = dot(_876, _974);\n    float _981 = _886.y;\n    if (_978 < _981)\n    {\n        return 1.0f;\n    }\n    float2 _996 = float2(dot(fa_light_texel(param_4), _974), dot(fa_light_texel(param_5), _974)) / _978.xx;\n    float _998 = _996.x;\n    bool _1001 = _998 < _881.x;\n    bool _1010;\n    if (!_1001)\n    {\n        _1010 = _998 > _881.z;\n    }\n    else\n    {\n        _1010 = _1001;\n    }\n    bool _1019;\n    if (!_1010)\n    {\n        _1019 = _996.y < _881.y;\n    }\n    else\n    {\n        _1019 = _1010;\n    }\n    bool _1028;\n    if (!_1019)\n    {\n        _1028 = _996.y > _881.w;\n    }\n    else\n    {\n        _1028 = _1019;\n    }\n    if (_1028)\n    {\n        return 1.0f;\n    }\n    float _1034 = _773.x;\n    float _1036;\n    if (_1034 > 0.0f)\n    {\n        _1036 = _1034;\n    }\n    else\n    {\n        _1036 = 1.5f * _898;\n    }\n    float2 param_10 = _996;\n    float4 param_11 = _881;\n    float param_12 = _978 - (_1036 * (1.0f + (0.5f * _949)));\n    float param_13 = _898;\n    float param_14 = 1.0f;\n    float param_15 = _886.z * 0.25f;\n    float param_16 = (_898 * min(_949, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _981, _886.z);\n    int param_18 = int(_768.z + 0.5f);\n    float param_19 = _768.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1301 = fa_light_sample(param, param_1);\n    float3 _1683 = _1301.direction;\n    float3 _1678 = _1301.color;\n    float _1685 = _1301.attenuation;\n    float _1680 = _1301.shadow;\n    int _1688 = _1301.type;\n    if ((_1688 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1683;\n        float _1317 = fa_shadow(param_2, param_3, param_4);\n        _1680 = _1317;\n        _1678 *= _1317;\n    }\n    else\n    {\n        bool _1328 = _1688 != 0;\n        bool _1334;\n        if (_1328)\n        {\n            _1334 = _1685 > 0.0f;\n        }\n        else\n        {\n            _1334 = _1328;\n        }\n        if (_1334)\n        {\n            int param_5 = li;\n            float3 param_6 = world_pos;\n            float3 param_7 = gn;\n            float3 param_8 = _1683;\n            float _1346 = fa_shadow_local(param_5, param_6, param_7, param_8);\n            _1680 = _1346;\n            _1678 *= _1346;\n        }\n    }\n    LightSample _1695 = { _1683, _1678, _1685, _1680, _1301._distance, _1688 };\n    return _1695;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _1359 = _730_fa_fog.w > 0.0f;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _730_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    if (_1366)\n    {\n        float3 _1374 = world_pos - _730_fa_camera_pos.xyz;\n        float _1381 = dot(_1374, _730_fa_fog_c.xyz);\n        bool _1385 = _730_fa_fog_c.w > 0.5f;\n        float _1386;\n        if (_1385)\n        {\n            _1386 = _1381;\n        }\n        else\n        {\n            _1386 = length(_1374);\n        }\n        float _1398 = _1386 - _730_fa_fog_b.x;\n        if (_1398 > 0.0f)\n        {\n            float _1407 = _730_fa_fog.w * _1398;\n            float tau = _1407 * _1407;\n            if (_730_fa_fog_b.y > 0.0f)\n            {\n                float _1423;\n                if (_1385)\n                {\n                    _1423 = world_pos.y - (_730_fa_fog_c.y * _1381);\n                }\n                else\n                {\n                    _1423 = _730_fa_camera_pos.y;\n                }\n                float _1444 = lerp(_1423, world_pos.y, clamp(_730_fa_fog_b.x / _1386, 0.0f, 1.0f));\n                float _1448 = world_pos.y - _1444;\n                float _1453 = _1444 - _730_fa_fog_b.z;\n                float _1458 = world_pos.y - _730_fa_fog_b.z;\n                bool _1461 = _1453 <= 0.0f;\n                bool _1462 = !_1461;\n                bool _1468;\n                if (_1462)\n                {\n                    _1468 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1468 = _1461;\n                }\n                float _1469;\n                if (_1468)\n                {\n                    _1469 = _730_fa_fog_b.y;\n                }\n                else\n                {\n                    _1469 = _730_fa_fog_b.y * exp(-min(_730_fa_fog_b.w * _1453, 80.0f));\n                }\n                bool _1496;\n                if (_1462)\n                {\n                    _1496 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1496 = _1461;\n                }\n                float _1497;\n                if (_1496)\n                {\n                    _1497 = _730_fa_fog_b.y * _1453;\n                }\n                else\n                {\n                    _1497 = (_730_fa_fog_b.y * (1.0f - exp(-min(_730_fa_fog_b.w * _1453, 80.0f)))) / _730_fa_fog_b.w;\n                }\n                bool _1522 = _1458 <= 0.0f;\n                bool _1529;\n                if (!_1522)\n                {\n                    _1529 = _730_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1529 = _1522;\n                }\n                float _1530;\n                if (_1529)\n                {\n                    _1530 = _730_fa_fog_b.y * _1458;\n                }\n                else\n                {\n                    _1530 = (_730_fa_fog_b.y * (1.0f - exp(-min(_730_fa_fog_b.w * _1458, 80.0f)))) / _730_fa_fog_b.w;\n                }\n                float _1557;\n                if (abs(_1448) < 0.001000000047497451305389404296875f)\n                {\n                    _1557 = _1469;\n                }\n                else\n                {\n                    _1557 = (_1530 - _1497) / _1448;\n                }\n                tau += (_1398 * max(_1557, 0.0f));\n            }\n            result = lerp(result, _730_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1595 = normalize(v_normal);\n    float3 lit = _730_fa_ambient.xyz * _1602_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1595;\n        float4 param_3 = v_shadow;\n        LightSample _1627 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1602_base.xyz * _1627.color) * max(dot(_1595, _1627.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1650 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1650, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
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
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_317",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_730",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1602",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
