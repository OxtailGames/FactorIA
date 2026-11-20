{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "9b526d852a58c0ab7f449c6f4c92253ae077b207eec8f1d2aa311601324d82ff",
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
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _292_fa_shadow_mat[4] : packoffset(c0);\n    float4 _292_fa_shadow_rect[4] : packoffset(c16);\n    float4 _292_fa_shadow_info[4] : packoffset(c20);\n    float4 _292_fa_shadow_split : packoffset(c24);\n    float4 _292_fa_shadow_cfg : packoffset(c25);\n    float4 _292_fa_shadow_bias : packoffset(c26);\n    float4 _292_fa_shadow_eye : packoffset(c27);\n    float4 _292_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _649_fa_camera_pos : packoffset(c0);\n    float4 _649_fa_ambient : packoffset(c1);\n    float4 _649_fa_base_color : packoffset(c2);\n    float4 _649_fa_emissive : packoffset(c3);\n    float4 _649_fa_model_emissive : packoffset(c4);\n    float4 _649_fa_pbr : packoffset(c5);\n    float4 _649_fa_maps : packoffset(c6);\n    float4 _649_fa_fog : packoffset(c7);\n    float4 _649_fa_fog_b : packoffset(c8);\n    float4 _649_fa_fog_c : packoffset(c9);\n    float4 _649_fa_counts : packoffset(c10);\n    float4 _649_fa_env_sky : packoffset(c11);\n    float4 _649_fa_env_horizon : packoffset(c12);\n    float4 _649_fa_time : packoffset(c13);\n    float4 _649_fa_cl_vpx : packoffset(c14);\n    float4 _649_fa_cl_vpy : packoffset(c15);\n    float4 _649_fa_cl_vpw : packoffset(c16);\n    float4 _649_fa_cl_fwd : packoffset(c17);\n    float4 _649_fa_cl_grid : packoffset(c18);\n    float4 _649_fa_cl_info : packoffset(c19);\n    float4 _649_fa_layers_a : packoffset(c20);\n    float4 _649_fa_layers_b : packoffset(c21);\n    float4 _649_fa_layers_c : packoffset(c22);\n    float4 _649_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1132_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_649_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _110 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _117 = fa_light_texel(param_1);\n    float _122 = _117.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _130 = _122 < 0.5f;\n    float3 l;\n    if (_130)\n    {\n        l = normalize(_110.xyz);\n    }\n    else\n    {\n        float3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / max(_144, 9.9999997473787516355514526367188e-05f).xxx;\n        float _159 = _144 / max(_110.w, 0.001000000047497451305389404296875f);\n        float _165 = clamp(1.0f - (_159 * _159), 0.0f, 1.0f);\n        atten = _165 * _165;\n        if (_122 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _180 = fa_light_texel(param_2);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            float4 _197 = fa_light_texel(param_3);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5f)\n            {\n                cos_inner = lerp(_190, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1206 = { l, _117.xyz * atten, atten, 1.0f, dist, _230 };\n    return _1206;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = _292_fa_shadow_split.x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = _292_fa_shadow_split.y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = _292_fa_shadow_split.z;\n            }\n            else\n            {\n                _308 = _292_fa_shadow_split.w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _348 = max(_292_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _353 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _359 = sqrt(1.0f - (_353 * _353));\n    float _367 = min(_359 / max(_353, 0.20000000298023223876953125f), 4.0f);\n    float _372;\n    if (_292_fa_shadow_bias.y > 0.0f)\n    {\n        _372 = _292_fa_shadow_bias.y;\n    }\n    else\n    {\n        _372 = 1.5f * _292_fa_shadow_info[ci].x;\n    }\n    float4 _397 = mul(float4(world + (n * (_372 * _359)), 1.0f), _292_fa_shadow_mat[ci]);\n    float _404 = _397.x;\n    bool _407 = _404 < _292_fa_shadow_rect[ci].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > _292_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < _292_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > _292_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0f;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0f;\n    }\n    float _450;\n    if (_292_fa_shadow_bias.x > 0.0f)\n    {\n        _450 = _292_fa_shadow_bias.x;\n    }\n    else\n    {\n        _450 = 1.5f * _292_fa_shadow_info[ci].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0f + (0.5f * _367))) / _348);\n    float _478 = ((_292_fa_shadow_info[ci].x * min(_367, 3.0f)) * 0.5f) / _348;\n    int _487 = int(_292_fa_shadow_cfg.z + 0.5f);\n    if (_487 == 1)\n    {\n        float2 param = _397.xy;\n        float4 param_1 = _292_fa_shadow_rect[ci];\n        float _498 = fa_shadow_depth(param, param_1);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = clamp(((_292_fa_shadow_cfg.w * _348) * 0.25f) / _292_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            float2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            float2 param_5 = _397.xy + (_542 * _292_fa_shadow_bias.zw);\n            float4 param_6 = _292_fa_shadow_rect[ci];\n            float _553 = fa_shadow_depth(param_5, param_6);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_469 - (sum / cnt), 0.0f) * _348) * _292_fa_shadow_cfg.w) / _292_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        float2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _397.xy + (_616 * _292_fa_shadow_bias.zw);\n        float4 param_11 = _292_fa_shadow_rect[ci];\n        float _627 = fa_shadow_depth(param_10, param_11);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_649_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _660 = int(_292_fa_shadow_cfg.x + 0.5f);\n    if (_660 < 1)\n    {\n        return 1.0f;\n    }\n    float _677 = dot(world - _292_fa_shadow_eye.xyz, _292_fa_shadow_fwd.xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > _292_fa_shadow_split.x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > _292_fa_shadow_split.y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > _292_fa_shadow_split.z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _744;\n        if (_744 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_292_fa_shadow_cfg.y > 0.0f)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _769 = _292_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _788 = _292_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _769, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _799 = clamp((_677 - (fa_shadow_split_at(param_7) - _788)) / _788, 0.0f, 1.0f);\n        if (_799 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _820;\n                if (_820 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1);\n    float3 _1213 = _859.direction;\n    float3 _1208 = _859.color;\n    float _1210 = _859.shadow;\n    int _1218 = _859.type;\n    if ((_1218 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1213;\n        float _875 = fa_shadow(param_2, param_3, param_4);\n        _1210 = _875;\n        _1208 *= _875;\n    }\n    LightSample _1225 = { _1213, _1208, _859.attenuation, _1210, _859._distance, _1218 };\n    return _1225;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _888 = _649_fa_fog.w > 0.0f;\n    bool _896;\n    if (!_888)\n    {\n        _896 = _649_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        float3 _904 = world_pos - _649_fa_camera_pos.xyz;\n        float _911 = dot(_904, _649_fa_fog_c.xyz);\n        bool _915 = _649_fa_fog_c.w > 0.5f;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - _649_fa_fog_b.x;\n        if (_928 > 0.0f)\n        {\n            float _937 = _649_fa_fog.w * _928;\n            float tau = _937 * _937;\n            if (_649_fa_fog_b.y > 0.0f)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (_649_fa_fog_c.y * _911);\n                }\n                else\n                {\n                    _953 = _649_fa_camera_pos.y;\n                }\n                float _974 = lerp(_953, world_pos.y, clamp(_649_fa_fog_b.x / _916, 0.0f, 1.0f));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - _649_fa_fog_b.z;\n                float _988 = world_pos.y - _649_fa_fog_b.z;\n                bool _991 = _983 <= 0.0f;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = _649_fa_fog_b.y;\n                }\n                else\n                {\n                    _999 = _649_fa_fog_b.y * exp(-min(_649_fa_fog_b.w * _983, 80.0f));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = _649_fa_fog_b.y * _983;\n                }\n                else\n                {\n                    _1027 = (_649_fa_fog_b.y * (1.0f - exp(-min(_649_fa_fog_b.w * _983, 80.0f)))) / _649_fa_fog_b.w;\n                }\n                bool _1052 = _988 <= 0.0f;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = _649_fa_fog_b.y * _988;\n                }\n                else\n                {\n                    _1060 = (_649_fa_fog_b.y * (1.0f - exp(-min(_649_fa_fog_b.w * _988, 80.0f)))) / _649_fa_fog_b.w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875f)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * max(_1087, 0.0f));\n            }\n            result = lerp(result, _649_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1125 = normalize(v_normal);\n    float3 lit = _649_fa_ambient.xyz * _1132_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1125;\n        float4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1132_base.xyz * _1157.color) * max(dot(_1125, _1157.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1180 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1180, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
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
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _292_fa_shadow_mat[4] : packoffset(c0);\n    float4 _292_fa_shadow_rect[4] : packoffset(c16);\n    float4 _292_fa_shadow_info[4] : packoffset(c20);\n    float4 _292_fa_shadow_split : packoffset(c24);\n    float4 _292_fa_shadow_cfg : packoffset(c25);\n    float4 _292_fa_shadow_bias : packoffset(c26);\n    float4 _292_fa_shadow_eye : packoffset(c27);\n    float4 _292_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _649_fa_camera_pos : packoffset(c0);\n    float4 _649_fa_ambient : packoffset(c1);\n    float4 _649_fa_base_color : packoffset(c2);\n    float4 _649_fa_emissive : packoffset(c3);\n    float4 _649_fa_model_emissive : packoffset(c4);\n    float4 _649_fa_pbr : packoffset(c5);\n    float4 _649_fa_maps : packoffset(c6);\n    float4 _649_fa_fog : packoffset(c7);\n    float4 _649_fa_fog_b : packoffset(c8);\n    float4 _649_fa_fog_c : packoffset(c9);\n    float4 _649_fa_counts : packoffset(c10);\n    float4 _649_fa_env_sky : packoffset(c11);\n    float4 _649_fa_env_horizon : packoffset(c12);\n    float4 _649_fa_time : packoffset(c13);\n    float4 _649_fa_cl_vpx : packoffset(c14);\n    float4 _649_fa_cl_vpy : packoffset(c15);\n    float4 _649_fa_cl_vpw : packoffset(c16);\n    float4 _649_fa_cl_fwd : packoffset(c17);\n    float4 _649_fa_cl_grid : packoffset(c18);\n    float4 _649_fa_cl_info : packoffset(c19);\n    float4 _649_fa_layers_a : packoffset(c20);\n    float4 _649_fa_layers_b : packoffset(c21);\n    float4 _649_fa_layers_c : packoffset(c22);\n    float4 _649_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1132_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_649_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _110 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _117 = fa_light_texel(param_1);\n    float _122 = _117.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _130 = _122 < 0.5f;\n    float3 l;\n    if (_130)\n    {\n        l = normalize(_110.xyz);\n    }\n    else\n    {\n        float3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / max(_144, 9.9999997473787516355514526367188e-05f).xxx;\n        float _159 = _144 / max(_110.w, 0.001000000047497451305389404296875f);\n        float _165 = clamp(1.0f - (_159 * _159), 0.0f, 1.0f);\n        atten = _165 * _165;\n        if (_122 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _180 = fa_light_texel(param_2);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            float4 _197 = fa_light_texel(param_3);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5f)\n            {\n                cos_inner = lerp(_190, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1206 = { l, _117.xyz * atten, atten, 1.0f, dist, _230 };\n    return _1206;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = _292_fa_shadow_split.x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = _292_fa_shadow_split.y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = _292_fa_shadow_split.z;\n            }\n            else\n            {\n                _308 = _292_fa_shadow_split.w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _348 = max(_292_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _353 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _359 = sqrt(1.0f - (_353 * _353));\n    float _367 = min(_359 / max(_353, 0.20000000298023223876953125f), 4.0f);\n    float _372;\n    if (_292_fa_shadow_bias.y > 0.0f)\n    {\n        _372 = _292_fa_shadow_bias.y;\n    }\n    else\n    {\n        _372 = 1.5f * _292_fa_shadow_info[ci].x;\n    }\n    float4 _397 = mul(float4(world + (n * (_372 * _359)), 1.0f), _292_fa_shadow_mat[ci]);\n    float _404 = _397.x;\n    bool _407 = _404 < _292_fa_shadow_rect[ci].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > _292_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < _292_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > _292_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0f;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0f;\n    }\n    float _450;\n    if (_292_fa_shadow_bias.x > 0.0f)\n    {\n        _450 = _292_fa_shadow_bias.x;\n    }\n    else\n    {\n        _450 = 1.5f * _292_fa_shadow_info[ci].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0f + (0.5f * _367))) / _348);\n    float _478 = ((_292_fa_shadow_info[ci].x * min(_367, 3.0f)) * 0.5f) / _348;\n    int _487 = int(_292_fa_shadow_cfg.z + 0.5f);\n    if (_487 == 1)\n    {\n        float2 param = _397.xy;\n        float4 param_1 = _292_fa_shadow_rect[ci];\n        float _498 = fa_shadow_depth(param, param_1);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = clamp(((_292_fa_shadow_cfg.w * _348) * 0.25f) / _292_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            float2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            float2 param_5 = _397.xy + (_542 * _292_fa_shadow_bias.zw);\n            float4 param_6 = _292_fa_shadow_rect[ci];\n            float _553 = fa_shadow_depth(param_5, param_6);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_469 - (sum / cnt), 0.0f) * _348) * _292_fa_shadow_cfg.w) / _292_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        float2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _397.xy + (_616 * _292_fa_shadow_bias.zw);\n        float4 param_11 = _292_fa_shadow_rect[ci];\n        float _627 = fa_shadow_depth(param_10, param_11);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_649_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _660 = int(_292_fa_shadow_cfg.x + 0.5f);\n    if (_660 < 1)\n    {\n        return 1.0f;\n    }\n    float _677 = dot(world - _292_fa_shadow_eye.xyz, _292_fa_shadow_fwd.xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > _292_fa_shadow_split.x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > _292_fa_shadow_split.y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > _292_fa_shadow_split.z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _744;\n        if (_744 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_292_fa_shadow_cfg.y > 0.0f)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _769 = _292_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _788 = _292_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _769, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _799 = clamp((_677 - (fa_shadow_split_at(param_7) - _788)) / _788, 0.0f, 1.0f);\n        if (_799 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _820;\n                if (_820 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1);\n    float3 _1213 = _859.direction;\n    float3 _1208 = _859.color;\n    float _1210 = _859.shadow;\n    int _1218 = _859.type;\n    if ((_1218 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1213;\n        float _875 = fa_shadow(param_2, param_3, param_4);\n        _1210 = _875;\n        _1208 *= _875;\n    }\n    LightSample _1225 = { _1213, _1208, _859.attenuation, _1210, _859._distance, _1218 };\n    return _1225;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _888 = _649_fa_fog.w > 0.0f;\n    bool _896;\n    if (!_888)\n    {\n        _896 = _649_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        float3 _904 = world_pos - _649_fa_camera_pos.xyz;\n        float _911 = dot(_904, _649_fa_fog_c.xyz);\n        bool _915 = _649_fa_fog_c.w > 0.5f;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - _649_fa_fog_b.x;\n        if (_928 > 0.0f)\n        {\n            float _937 = _649_fa_fog.w * _928;\n            float tau = _937 * _937;\n            if (_649_fa_fog_b.y > 0.0f)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (_649_fa_fog_c.y * _911);\n                }\n                else\n                {\n                    _953 = _649_fa_camera_pos.y;\n                }\n                float _974 = lerp(_953, world_pos.y, clamp(_649_fa_fog_b.x / _916, 0.0f, 1.0f));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - _649_fa_fog_b.z;\n                float _988 = world_pos.y - _649_fa_fog_b.z;\n                bool _991 = _983 <= 0.0f;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = _649_fa_fog_b.y;\n                }\n                else\n                {\n                    _999 = _649_fa_fog_b.y * exp(-min(_649_fa_fog_b.w * _983, 80.0f));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = _649_fa_fog_b.y * _983;\n                }\n                else\n                {\n                    _1027 = (_649_fa_fog_b.y * (1.0f - exp(-min(_649_fa_fog_b.w * _983, 80.0f)))) / _649_fa_fog_b.w;\n                }\n                bool _1052 = _988 <= 0.0f;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = _649_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = _649_fa_fog_b.y * _988;\n                }\n                else\n                {\n                    _1060 = (_649_fa_fog_b.y * (1.0f - exp(-min(_649_fa_fog_b.w * _988, 80.0f)))) / _649_fa_fog_b.w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875f)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * max(_1087, 0.0f));\n            }\n            result = lerp(result, _649_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1125 = normalize(v_normal);\n    float3 lit = _649_fa_ambient.xyz * _1132_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1125;\n        float4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1132_base.xyz * _1157.color) * max(dot(_1125, _1157.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1180 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1180, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
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
