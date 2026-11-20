{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "559609183f39d15a98638319a0abdbf558e86e30a9c2dcc930141d2b969fc0f0",
  "slang": "metal_macos",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_shadow_coord(thread const float3& world)\n{\n    return float4(world, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& v_shadow, thread float4& gl_Position, constant fa_mesh_vs_params& _129)\n{\n    float3 param = fa_position;\n    float3 _109 = fa_world_position(param, fa_model);\n    v_pos = _109;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    float3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = _129.fa_view_proj * float4(_109, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.v_shadow, out.gl_Position, _129);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _618)\n{\n    return min(int(_618.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _86)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _100 = _86.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_100)\n    {\n        l = fast::normalize(_86.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _118 = _86.fa_light_pos[li].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / float3(fast::max(_120, 9.9999997473787516355514526367188e-05));\n        float _136 = _120 / fast::max(_86.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _142 = fast::clamp(1.0 - (_136 * _136), 0.0, 1.0);\n        atten = _142 * _142;\n        if (_86.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_86.fa_light_dir[li].w, mix(_86.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_86.fa_light_dir[li].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (_86.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _86.fa_light_color[li].xyz * atten, atten, 1.0, dist, _194 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _256)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = _256.fa_shadow_split.x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = _256.fa_shadow_split.y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = _256.fa_shadow_split.z;\n            }\n            else\n            {\n                _272 = _256.fa_shadow_split.w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    float _317 = fast::max(_256.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _322 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _328 = sqrt(1.0 - (_322 * _322));\n    float _336 = fast::min(_328 / fast::max(_322, 0.20000000298023223876953125), 4.0);\n    float _341;\n    if (_256.fa_shadow_bias.y > 0.0)\n    {\n        _341 = _256.fa_shadow_bias.y;\n    }\n    else\n    {\n        _341 = 1.5 * _256.fa_shadow_info[ci].x;\n    }\n    float4 _366 = _256.fa_shadow_mat[ci] * float4(world + (n * (_341 * _328)), 1.0);\n    float _373 = _366.x;\n    bool _376 = _373 < _256.fa_shadow_rect[ci].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > _256.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < _256.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > _256.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0;\n    }\n    float _419;\n    if (_256.fa_shadow_bias.x > 0.0)\n    {\n        _419 = _256.fa_shadow_bias.x;\n    }\n    else\n    {\n        _419 = 1.5 * _256.fa_shadow_info[ci].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0 + (0.5 * _336))) / _317);\n    float _447 = ((_256.fa_shadow_info[ci].x * fast::min(_336, 3.0)) * 0.5) / _317;\n    int _456 = int(_256.fa_shadow_cfg.z + 0.5);\n    if (_456 == 1)\n    {\n        float2 param = _366.xy;\n        float4 param_1 = _256.fa_shadow_rect[ci];\n        float _467 = fa_shadow_depth(param, param_1, fa_full_shadow_tex, fa_full_shadow_smp);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = fast::clamp(((_256.fa_shadow_cfg.w * _317) * 0.25) / _256.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            float2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            float2 param_5 = _366.xy + (_511 * _256.fa_shadow_bias.zw);\n            float4 param_6 = _256.fa_shadow_rect[ci];\n            float _522 = fa_shadow_depth(param_5, param_6, fa_full_shadow_tex, fa_full_shadow_smp);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_438 - (sum / cnt), 0.0) * _317) * _256.fa_shadow_cfg.w) / _256.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        float2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _366.xy + (_585 * _256.fa_shadow_bias.zw);\n        float4 param_11 = _256.fa_shadow_rect[ci];\n        float _596 = fa_shadow_depth(param_10, param_11, fa_full_shadow_tex, fa_full_shadow_smp);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    if (_618.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _629 = int(_256.fa_shadow_cfg.x + 0.5);\n    if (_629 < 1)\n    {\n        return 1.0;\n    }\n    float _646 = dot(world - _256.fa_shadow_eye.xyz, _256.fa_shadow_fwd.xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param, _256))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > _256.fa_shadow_split.x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > _256.fa_shadow_split.y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > _256.fa_shadow_split.z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp);\n        s = _713;\n        if (_713 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_256.fa_shadow_cfg.y > 0.0)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5, _256);\n        }\n        else\n        {\n            _738 = _256.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _757 = _256.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _256) - _738, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _768 = fast::clamp((_646 - (fa_shadow_split_at(param_7, _256) - _757)) / _757, 0.0, 1.0);\n        if (_768 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp);\n                s2 = _789;\n                if (_789 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_lights& _86, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1, _86);\n    float3 _1188 = _829.direction;\n    float3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n        _1185 = _845;\n        _1183 = _86.fa_light_color[li].xyz * (_1190 * _845);\n    }\n    return LightSample{ _1188, _1183, _1190, _1185, _829._distance, _1193 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _618)\n{\n    bool _863 = _618.fa_fog.w > 0.0;\n    bool _871;\n    if (!_863)\n    {\n        _871 = _618.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        float3 _879 = world_pos - _618.fa_camera_pos.xyz;\n        float _886 = dot(_879, _618.fa_fog_c.xyz);\n        bool _890 = _618.fa_fog_c.w > 0.5;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - _618.fa_fog_b.x;\n        if (_903 > 0.0)\n        {\n            float _912 = _618.fa_fog.w * _903;\n            float tau = _912 * _912;\n            if (_618.fa_fog_b.y > 0.0)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (_618.fa_fog_c.y * _886);\n                }\n                else\n                {\n                    _928 = _618.fa_camera_pos.y;\n                }\n                float _949 = mix(_928, world_pos.y, fast::clamp(_618.fa_fog_b.x / _891, 0.0, 1.0));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - _618.fa_fog_b.z;\n                float _963 = world_pos.y - _618.fa_fog_b.z;\n                bool _966 = _958 <= 0.0;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = _618.fa_fog_b.y;\n                }\n                else\n                {\n                    _974 = _618.fa_fog_b.y * exp(-fast::min(_618.fa_fog_b.w * _958, 80.0));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = _618.fa_fog_b.y * _958;\n                }\n                else\n                {\n                    _1002 = (_618.fa_fog_b.y * (1.0 - exp(-fast::min(_618.fa_fog_b.w * _958, 80.0)))) / _618.fa_fog_b.w;\n                }\n                bool _1027 = _963 <= 0.0;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = _618.fa_fog_b.y * _963;\n                }\n                else\n                {\n                    _1035 = (_618.fa_fog_b.y * (1.0 - exp(-fast::min(_618.fa_fog_b.w * _963, 80.0)))) / _618.fa_fog_b.w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * fast::max(_1062, 0.0));\n            }\n            result = mix(result, _618.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_lights& _86, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618, thread float3& v_normal, constant fa_material& _1107, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1100 = fast::normalize(v_normal);\n    float3 lit = _618.fa_ambient.xyz * _1107.base.xyz;\n    for (int i = 0; i < fa_light_count(_618); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1100;\n        float4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3, _86, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n        lit += ((_1107.base.xyz * _1132.color) * fast::max(dot(_1100, _1132.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1155 = fa_apply_fog(param_4, param_5, _618);\n    fa_frag_color = float4(_1155, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _618 [[buffer(1)]], constant fa_lights& _86 [[buffer(2)]], constant fa_material& _1107 [[buffer(5)]], constant fa_shadows& _256 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_86, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618, in.v_normal, _1107, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
            "msl_buffer_n": 5
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
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _71)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_71.fa_joint_rows[_61] * weights[i]);\n        r1 += (_71.fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71.fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_shadow_coord(thread const float3& world)\n{\n    return float4(world, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& v_shadow, thread float4& gl_Position, constant fa_mesh_vs_params& _247)\n{\n    float3 param = fa_position;\n    float3 _227 = fa_world_position(param, fa_model);\n    v_pos = _227;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    float3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = _247.fa_view_proj * float4(_227, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _247 [[buffer(0)]], constant fa_skin& _71 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _71);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.v_shadow, out.gl_Position, _247);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _618)\n{\n    return min(int(_618.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _86)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _100 = _86.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_100)\n    {\n        l = fast::normalize(_86.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _118 = _86.fa_light_pos[li].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / float3(fast::max(_120, 9.9999997473787516355514526367188e-05));\n        float _136 = _120 / fast::max(_86.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _142 = fast::clamp(1.0 - (_136 * _136), 0.0, 1.0);\n        atten = _142 * _142;\n        if (_86.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_86.fa_light_dir[li].w, mix(_86.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_86.fa_light_dir[li].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (_86.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _86.fa_light_color[li].xyz * atten, atten, 1.0, dist, _194 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _256)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = _256.fa_shadow_split.x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = _256.fa_shadow_split.y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = _256.fa_shadow_split.z;\n            }\n            else\n            {\n                _272 = _256.fa_shadow_split.w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    float _317 = fast::max(_256.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _322 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _328 = sqrt(1.0 - (_322 * _322));\n    float _336 = fast::min(_328 / fast::max(_322, 0.20000000298023223876953125), 4.0);\n    float _341;\n    if (_256.fa_shadow_bias.y > 0.0)\n    {\n        _341 = _256.fa_shadow_bias.y;\n    }\n    else\n    {\n        _341 = 1.5 * _256.fa_shadow_info[ci].x;\n    }\n    float4 _366 = _256.fa_shadow_mat[ci] * float4(world + (n * (_341 * _328)), 1.0);\n    float _373 = _366.x;\n    bool _376 = _373 < _256.fa_shadow_rect[ci].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > _256.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < _256.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > _256.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0;\n    }\n    float _419;\n    if (_256.fa_shadow_bias.x > 0.0)\n    {\n        _419 = _256.fa_shadow_bias.x;\n    }\n    else\n    {\n        _419 = 1.5 * _256.fa_shadow_info[ci].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0 + (0.5 * _336))) / _317);\n    float _447 = ((_256.fa_shadow_info[ci].x * fast::min(_336, 3.0)) * 0.5) / _317;\n    int _456 = int(_256.fa_shadow_cfg.z + 0.5);\n    if (_456 == 1)\n    {\n        float2 param = _366.xy;\n        float4 param_1 = _256.fa_shadow_rect[ci];\n        float _467 = fa_shadow_depth(param, param_1, fa_full_shadow_tex, fa_full_shadow_smp);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = fast::clamp(((_256.fa_shadow_cfg.w * _317) * 0.25) / _256.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            float2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            float2 param_5 = _366.xy + (_511 * _256.fa_shadow_bias.zw);\n            float4 param_6 = _256.fa_shadow_rect[ci];\n            float _522 = fa_shadow_depth(param_5, param_6, fa_full_shadow_tex, fa_full_shadow_smp);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_438 - (sum / cnt), 0.0) * _317) * _256.fa_shadow_cfg.w) / _256.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        float2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _366.xy + (_585 * _256.fa_shadow_bias.zw);\n        float4 param_11 = _256.fa_shadow_rect[ci];\n        float _596 = fa_shadow_depth(param_10, param_11, fa_full_shadow_tex, fa_full_shadow_smp);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    if (_618.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _629 = int(_256.fa_shadow_cfg.x + 0.5);\n    if (_629 < 1)\n    {\n        return 1.0;\n    }\n    float _646 = dot(world - _256.fa_shadow_eye.xyz, _256.fa_shadow_fwd.xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param, _256))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > _256.fa_shadow_split.x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > _256.fa_shadow_split.y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > _256.fa_shadow_split.z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp);\n        s = _713;\n        if (_713 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_256.fa_shadow_cfg.y > 0.0)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5, _256);\n        }\n        else\n        {\n            _738 = _256.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _757 = _256.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _256) - _738, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _768 = fast::clamp((_646 - (fa_shadow_split_at(param_7, _256) - _757)) / _757, 0.0, 1.0);\n        if (_768 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp);\n                s2 = _789;\n                if (_789 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_lights& _86, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1, _86);\n    float3 _1188 = _829.direction;\n    float3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n        _1185 = _845;\n        _1183 = _86.fa_light_color[li].xyz * (_1190 * _845);\n    }\n    return LightSample{ _1188, _1183, _1190, _1185, _829._distance, _1193 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _618)\n{\n    bool _863 = _618.fa_fog.w > 0.0;\n    bool _871;\n    if (!_863)\n    {\n        _871 = _618.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        float3 _879 = world_pos - _618.fa_camera_pos.xyz;\n        float _886 = dot(_879, _618.fa_fog_c.xyz);\n        bool _890 = _618.fa_fog_c.w > 0.5;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - _618.fa_fog_b.x;\n        if (_903 > 0.0)\n        {\n            float _912 = _618.fa_fog.w * _903;\n            float tau = _912 * _912;\n            if (_618.fa_fog_b.y > 0.0)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (_618.fa_fog_c.y * _886);\n                }\n                else\n                {\n                    _928 = _618.fa_camera_pos.y;\n                }\n                float _949 = mix(_928, world_pos.y, fast::clamp(_618.fa_fog_b.x / _891, 0.0, 1.0));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - _618.fa_fog_b.z;\n                float _963 = world_pos.y - _618.fa_fog_b.z;\n                bool _966 = _958 <= 0.0;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = _618.fa_fog_b.y;\n                }\n                else\n                {\n                    _974 = _618.fa_fog_b.y * exp(-fast::min(_618.fa_fog_b.w * _958, 80.0));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = _618.fa_fog_b.y * _958;\n                }\n                else\n                {\n                    _1002 = (_618.fa_fog_b.y * (1.0 - exp(-fast::min(_618.fa_fog_b.w * _958, 80.0)))) / _618.fa_fog_b.w;\n                }\n                bool _1027 = _963 <= 0.0;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = _618.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = _618.fa_fog_b.y * _963;\n                }\n                else\n                {\n                    _1035 = (_618.fa_fog_b.y * (1.0 - exp(-fast::min(_618.fa_fog_b.w * _963, 80.0)))) / _618.fa_fog_b.w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * fast::max(_1062, 0.0));\n            }\n            result = mix(result, _618.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_lights& _86, thread float4& gl_FragCoord, constant fa_shadows& _256, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _618, thread float3& v_normal, constant fa_material& _1107, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1100 = fast::normalize(v_normal);\n    float3 lit = _618.fa_ambient.xyz * _1107.base.xyz;\n    for (int i = 0; i < fa_light_count(_618); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1100;\n        float4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3, _86, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618);\n        lit += ((_1107.base.xyz * _1132.color) * fast::max(dot(_1100, _1132.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1155 = fa_apply_fog(param_4, param_5, _618);\n    fa_frag_color = float4(_1155, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _618 [[buffer(1)]], constant fa_lights& _86 [[buffer(2)]], constant fa_material& _1107 [[buffer(5)]], constant fa_shadows& _256 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_86, gl_FragCoord, _256, fa_full_shadow_tex, fa_full_shadow_smp, _618, in.v_normal, _1107, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
            "msl_buffer_n": 5
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
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
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
