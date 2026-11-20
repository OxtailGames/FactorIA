{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "559609183f39d15a98638319a0abdbf558e86e30a9c2dcc930141d2b969fc0f0",
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
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _109 = fa_world_position(param);\n    v_pos = _109;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_109, 1.0f), _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _86_fa_light_pos[32] : packoffset(c0);\n    float4 _86_fa_light_color[32] : packoffset(c32);\n    float4 _86_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _256_fa_shadow_mat[4] : packoffset(c0);\n    float4 _256_fa_shadow_rect[4] : packoffset(c16);\n    float4 _256_fa_shadow_info[4] : packoffset(c20);\n    float4 _256_fa_shadow_split : packoffset(c24);\n    float4 _256_fa_shadow_cfg : packoffset(c25);\n    float4 _256_fa_shadow_bias : packoffset(c26);\n    float4 _256_fa_shadow_eye : packoffset(c27);\n    float4 _256_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _618_fa_camera_pos : packoffset(c0);\n    float4 _618_fa_ambient : packoffset(c1);\n    float4 _618_fa_base_color : packoffset(c2);\n    float4 _618_fa_emissive : packoffset(c3);\n    float4 _618_fa_model_emissive : packoffset(c4);\n    float4 _618_fa_pbr : packoffset(c5);\n    float4 _618_fa_maps : packoffset(c6);\n    float4 _618_fa_fog : packoffset(c7);\n    float4 _618_fa_fog_b : packoffset(c8);\n    float4 _618_fa_fog_c : packoffset(c9);\n    float4 _618_fa_counts : packoffset(c10);\n    float4 _618_fa_env_sky : packoffset(c11);\n    float4 _618_fa_env_horizon : packoffset(c12);\n    float4 _618_fa_time : packoffset(c13);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1107_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_shadow_tex : register(t0);\nSamplerState fa_full_shadow_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_618_fa_counts.x), 32);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _100 = _86_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_100)\n    {\n        l = normalize(_86_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _118 = _86_fa_light_pos[li].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / max(_120, 9.9999997473787516355514526367188e-05f).xxx;\n        float _136 = _120 / max(_86_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _142 = clamp(1.0f - (_136 * _136), 0.0f, 1.0f);\n        atten = _142 * _142;\n        if (_86_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_86_fa_light_dir[li].w, lerp(_86_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_86_fa_light_dir[li].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (_86_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1181 = { l, _86_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _194 };\n    return _1181;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = _256_fa_shadow_split.x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = _256_fa_shadow_split.y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = _256_fa_shadow_split.z;\n            }\n            else\n            {\n                _272 = _256_fa_shadow_split.w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _317 = max(_256_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _322 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _328 = sqrt(1.0f - (_322 * _322));\n    float _336 = min(_328 / max(_322, 0.20000000298023223876953125f), 4.0f);\n    float _341;\n    if (_256_fa_shadow_bias.y > 0.0f)\n    {\n        _341 = _256_fa_shadow_bias.y;\n    }\n    else\n    {\n        _341 = 1.5f * _256_fa_shadow_info[ci].x;\n    }\n    float4 _366 = mul(float4(world + (n * (_341 * _328)), 1.0f), _256_fa_shadow_mat[ci]);\n    float _373 = _366.x;\n    bool _376 = _373 < _256_fa_shadow_rect[ci].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > _256_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < _256_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > _256_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0f;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0f;\n    }\n    float _419;\n    if (_256_fa_shadow_bias.x > 0.0f)\n    {\n        _419 = _256_fa_shadow_bias.x;\n    }\n    else\n    {\n        _419 = 1.5f * _256_fa_shadow_info[ci].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0f + (0.5f * _336))) / _317);\n    float _447 = ((_256_fa_shadow_info[ci].x * min(_336, 3.0f)) * 0.5f) / _317;\n    int _456 = int(_256_fa_shadow_cfg.z + 0.5f);\n    if (_456 == 1)\n    {\n        float2 param = _366.xy;\n        float4 param_1 = _256_fa_shadow_rect[ci];\n        float _467 = fa_shadow_depth(param, param_1);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = clamp(((_256_fa_shadow_cfg.w * _317) * 0.25f) / _256_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            float2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            float2 param_5 = _366.xy + (_511 * _256_fa_shadow_bias.zw);\n            float4 param_6 = _256_fa_shadow_rect[ci];\n            float _522 = fa_shadow_depth(param_5, param_6);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_438 - (sum / cnt), 0.0f) * _317) * _256_fa_shadow_cfg.w) / _256_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        float2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _366.xy + (_585 * _256_fa_shadow_bias.zw);\n        float4 param_11 = _256_fa_shadow_rect[ci];\n        float _596 = fa_shadow_depth(param_10, param_11);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_618_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _629 = int(_256_fa_shadow_cfg.x + 0.5f);\n    if (_629 < 1)\n    {\n        return 1.0f;\n    }\n    float _646 = dot(world - _256_fa_shadow_eye.xyz, _256_fa_shadow_fwd.xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > _256_fa_shadow_split.x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > _256_fa_shadow_split.y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > _256_fa_shadow_split.z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _713;\n        if (_713 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_256_fa_shadow_cfg.y > 0.0f)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _738 = _256_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _757 = _256_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _738, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _768 = clamp((_646 - (fa_shadow_split_at(param_7) - _757)) / _757, 0.0f, 1.0f);\n        if (_768 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _789;\n                if (_789 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1);\n    float3 _1188 = _829.direction;\n    float3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4);\n        _1185 = _845;\n        _1183 = _86_fa_light_color[li].xyz * (_1190 * _845);\n    }\n    LightSample _1200 = { _1188, _1183, _1190, _1185, _829._distance, _1193 };\n    return _1200;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _863 = _618_fa_fog.w > 0.0f;\n    bool _871;\n    if (!_863)\n    {\n        _871 = _618_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        float3 _879 = world_pos - _618_fa_camera_pos.xyz;\n        float _886 = dot(_879, _618_fa_fog_c.xyz);\n        bool _890 = _618_fa_fog_c.w > 0.5f;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - _618_fa_fog_b.x;\n        if (_903 > 0.0f)\n        {\n            float _912 = _618_fa_fog.w * _903;\n            float tau = _912 * _912;\n            if (_618_fa_fog_b.y > 0.0f)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (_618_fa_fog_c.y * _886);\n                }\n                else\n                {\n                    _928 = _618_fa_camera_pos.y;\n                }\n                float _949 = lerp(_928, world_pos.y, clamp(_618_fa_fog_b.x / _891, 0.0f, 1.0f));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - _618_fa_fog_b.z;\n                float _963 = world_pos.y - _618_fa_fog_b.z;\n                bool _966 = _958 <= 0.0f;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = _618_fa_fog_b.y;\n                }\n                else\n                {\n                    _974 = _618_fa_fog_b.y * exp(-min(_618_fa_fog_b.w * _958, 80.0f));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = _618_fa_fog_b.y * _958;\n                }\n                else\n                {\n                    _1002 = (_618_fa_fog_b.y * (1.0f - exp(-min(_618_fa_fog_b.w * _958, 80.0f)))) / _618_fa_fog_b.w;\n                }\n                bool _1027 = _963 <= 0.0f;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = _618_fa_fog_b.y * _963;\n                }\n                else\n                {\n                    _1035 = (_618_fa_fog_b.y * (1.0f - exp(-min(_618_fa_fog_b.w * _963, 80.0f)))) / _618_fa_fog_b.w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875f)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * max(_1062, 0.0f));\n            }\n            result = lerp(result, _618_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1100 = normalize(v_normal);\n    float3 lit = _618_fa_ambient.xyz * _1107_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1100;\n        float4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1107_base.xyz * _1132.color) * max(dot(_1100, _1132.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1155 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1155, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
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
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _71_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _247_fa_view_proj : packoffset(c0);\n    row_major float4x4 _247_fa_light_vp : packoffset(c4);\n    float4 _247_fa_uv_scale : packoffset(c8);\n    float4 _247_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_71_fa_joint_rows[_61] * weights[i]);\n        r1 += (_71_fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71_fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return float4(world, 1.0f);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _227 = fa_world_position(param);\n    v_pos = _227;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_227, 1.0f), _247_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _86_fa_light_pos[32] : packoffset(c0);\n    float4 _86_fa_light_color[32] : packoffset(c32);\n    float4 _86_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _256_fa_shadow_mat[4] : packoffset(c0);\n    float4 _256_fa_shadow_rect[4] : packoffset(c16);\n    float4 _256_fa_shadow_info[4] : packoffset(c20);\n    float4 _256_fa_shadow_split : packoffset(c24);\n    float4 _256_fa_shadow_cfg : packoffset(c25);\n    float4 _256_fa_shadow_bias : packoffset(c26);\n    float4 _256_fa_shadow_eye : packoffset(c27);\n    float4 _256_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _618_fa_camera_pos : packoffset(c0);\n    float4 _618_fa_ambient : packoffset(c1);\n    float4 _618_fa_base_color : packoffset(c2);\n    float4 _618_fa_emissive : packoffset(c3);\n    float4 _618_fa_model_emissive : packoffset(c4);\n    float4 _618_fa_pbr : packoffset(c5);\n    float4 _618_fa_maps : packoffset(c6);\n    float4 _618_fa_fog : packoffset(c7);\n    float4 _618_fa_fog_b : packoffset(c8);\n    float4 _618_fa_fog_c : packoffset(c9);\n    float4 _618_fa_counts : packoffset(c10);\n    float4 _618_fa_env_sky : packoffset(c11);\n    float4 _618_fa_env_horizon : packoffset(c12);\n    float4 _618_fa_time : packoffset(c13);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _1107_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_shadow_tex : register(t0);\nSamplerState fa_full_shadow_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_618_fa_counts.x), 32);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _100 = _86_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_100)\n    {\n        l = normalize(_86_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _118 = _86_fa_light_pos[li].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / max(_120, 9.9999997473787516355514526367188e-05f).xxx;\n        float _136 = _120 / max(_86_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _142 = clamp(1.0f - (_136 * _136), 0.0f, 1.0f);\n        atten = _142 * _142;\n        if (_86_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_86_fa_light_dir[li].w, lerp(_86_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_86_fa_light_dir[li].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (_86_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1181 = { l, _86_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _194 };\n    return _1181;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = _256_fa_shadow_split.x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = _256_fa_shadow_split.y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = _256_fa_shadow_split.z;\n            }\n            else\n            {\n                _272 = _256_fa_shadow_split.w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _317 = max(_256_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _322 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _328 = sqrt(1.0f - (_322 * _322));\n    float _336 = min(_328 / max(_322, 0.20000000298023223876953125f), 4.0f);\n    float _341;\n    if (_256_fa_shadow_bias.y > 0.0f)\n    {\n        _341 = _256_fa_shadow_bias.y;\n    }\n    else\n    {\n        _341 = 1.5f * _256_fa_shadow_info[ci].x;\n    }\n    float4 _366 = mul(float4(world + (n * (_341 * _328)), 1.0f), _256_fa_shadow_mat[ci]);\n    float _373 = _366.x;\n    bool _376 = _373 < _256_fa_shadow_rect[ci].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > _256_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < _256_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > _256_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0f;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0f;\n    }\n    float _419;\n    if (_256_fa_shadow_bias.x > 0.0f)\n    {\n        _419 = _256_fa_shadow_bias.x;\n    }\n    else\n    {\n        _419 = 1.5f * _256_fa_shadow_info[ci].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0f + (0.5f * _336))) / _317);\n    float _447 = ((_256_fa_shadow_info[ci].x * min(_336, 3.0f)) * 0.5f) / _317;\n    int _456 = int(_256_fa_shadow_cfg.z + 0.5f);\n    if (_456 == 1)\n    {\n        float2 param = _366.xy;\n        float4 param_1 = _256_fa_shadow_rect[ci];\n        float _467 = fa_shadow_depth(param, param_1);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = clamp(((_256_fa_shadow_cfg.w * _317) * 0.25f) / _256_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            float2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            float2 param_5 = _366.xy + (_511 * _256_fa_shadow_bias.zw);\n            float4 param_6 = _256_fa_shadow_rect[ci];\n            float _522 = fa_shadow_depth(param_5, param_6);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_438 - (sum / cnt), 0.0f) * _317) * _256_fa_shadow_cfg.w) / _256_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        float2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _366.xy + (_585 * _256_fa_shadow_bias.zw);\n        float4 param_11 = _256_fa_shadow_rect[ci];\n        float _596 = fa_shadow_depth(param_10, param_11);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_618_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _629 = int(_256_fa_shadow_cfg.x + 0.5f);\n    if (_629 < 1)\n    {\n        return 1.0f;\n    }\n    float _646 = dot(world - _256_fa_shadow_eye.xyz, _256_fa_shadow_fwd.xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > _256_fa_shadow_split.x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > _256_fa_shadow_split.y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > _256_fa_shadow_split.z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _713;\n        if (_713 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_256_fa_shadow_cfg.y > 0.0f)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _738 = _256_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _757 = _256_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _738, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _768 = clamp((_646 - (fa_shadow_split_at(param_7) - _757)) / _757, 0.0f, 1.0f);\n        if (_768 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _789;\n                if (_789 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float3 param = coord.xyz / coord.w.xxx;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1);\n    float3 _1188 = _829.direction;\n    float3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4);\n        _1185 = _845;\n        _1183 = _86_fa_light_color[li].xyz * (_1190 * _845);\n    }\n    LightSample _1200 = { _1188, _1183, _1190, _1185, _829._distance, _1193 };\n    return _1200;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _863 = _618_fa_fog.w > 0.0f;\n    bool _871;\n    if (!_863)\n    {\n        _871 = _618_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        float3 _879 = world_pos - _618_fa_camera_pos.xyz;\n        float _886 = dot(_879, _618_fa_fog_c.xyz);\n        bool _890 = _618_fa_fog_c.w > 0.5f;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - _618_fa_fog_b.x;\n        if (_903 > 0.0f)\n        {\n            float _912 = _618_fa_fog.w * _903;\n            float tau = _912 * _912;\n            if (_618_fa_fog_b.y > 0.0f)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (_618_fa_fog_c.y * _886);\n                }\n                else\n                {\n                    _928 = _618_fa_camera_pos.y;\n                }\n                float _949 = lerp(_928, world_pos.y, clamp(_618_fa_fog_b.x / _891, 0.0f, 1.0f));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - _618_fa_fog_b.z;\n                float _963 = world_pos.y - _618_fa_fog_b.z;\n                bool _966 = _958 <= 0.0f;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = _618_fa_fog_b.y;\n                }\n                else\n                {\n                    _974 = _618_fa_fog_b.y * exp(-min(_618_fa_fog_b.w * _958, 80.0f));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = _618_fa_fog_b.y * _958;\n                }\n                else\n                {\n                    _1002 = (_618_fa_fog_b.y * (1.0f - exp(-min(_618_fa_fog_b.w * _958, 80.0f)))) / _618_fa_fog_b.w;\n                }\n                bool _1027 = _963 <= 0.0f;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = _618_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = _618_fa_fog_b.y * _963;\n                }\n                else\n                {\n                    _1035 = (_618_fa_fog_b.y * (1.0f - exp(-min(_618_fa_fog_b.w * _963, 80.0f)))) / _618_fa_fog_b.w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875f)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * max(_1062, 0.0f));\n            }\n            result = lerp(result, _618_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _1100 = normalize(v_normal);\n    float3 lit = _618_fa_ambient.xyz * _1107_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1100;\n        float4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_1107_base.xyz * _1132.color) * max(dot(_1100, _1132.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1155 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_1155, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
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
