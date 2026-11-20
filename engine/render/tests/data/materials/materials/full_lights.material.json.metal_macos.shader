{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "0813083d052679fd3e24a7e53ac90c2bb9086c90ad668f78e1c00d92d1fcf9ae",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _649)\n{\n    return min(int(_649.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    int param = li * 4;\n    float4 _110 = fa_light_texel(param, fa_full_light_tex, fa_full_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _117 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float _122 = _117.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _130 = _122 < 0.5;\n    float3 l;\n    if (_130)\n    {\n        l = fast::normalize(_110.xyz);\n    }\n    else\n    {\n        float3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / float3(fast::max(_144, 9.9999997473787516355514526367188e-05));\n        float _159 = _144 / fast::max(_110.w, 0.001000000047497451305389404296875);\n        float _165 = fast::clamp(1.0 - (_159 * _159), 0.0, 1.0);\n        atten = _165 * _165;\n        if (_122 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _180 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            float4 _197 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5)\n            {\n                cos_inner = mix(_190, 1.0, 0.25);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, fast::normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _117.xyz * atten, atten, 1.0, dist, _230 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _292)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = _292.fa_shadow_split.x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = _292.fa_shadow_split.y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = _292.fa_shadow_split.z;\n            }\n            else\n            {\n                _308 = _292.fa_shadow_split.w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_full_shadow_smp, texture2d<float> fa_full_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex)\n{\n    float _348 = fast::max(_292.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _353 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _359 = sqrt(1.0 - (_353 * _353));\n    float _367 = fast::min(_359 / fast::max(_353, 0.20000000298023223876953125), 4.0);\n    float _372;\n    if (_292.fa_shadow_bias.y > 0.0)\n    {\n        _372 = _292.fa_shadow_bias.y;\n    }\n    else\n    {\n        _372 = 1.5 * _292.fa_shadow_info[ci].x;\n    }\n    float4 _397 = _292.fa_shadow_mat[ci] * float4(world + (n * (_372 * _359)), 1.0);\n    float _404 = _397.x;\n    bool _407 = _404 < _292.fa_shadow_rect[ci].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > _292.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < _292.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > _292.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0;\n    }\n    float _450;\n    if (_292.fa_shadow_bias.x > 0.0)\n    {\n        _450 = _292.fa_shadow_bias.x;\n    }\n    else\n    {\n        _450 = 1.5 * _292.fa_shadow_info[ci].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0 + (0.5 * _367))) / _348);\n    float _478 = ((_292.fa_shadow_info[ci].x * fast::min(_367, 3.0)) * 0.5) / _348;\n    int _487 = int(_292.fa_shadow_cfg.z + 0.5);\n    if (_487 == 1)\n    {\n        float2 param = _397.xy;\n        float4 param_1 = _292.fa_shadow_rect[ci];\n        float _498 = fa_shadow_depth(param, param_1, fa_full_shadow_smp, fa_full_shadow_tex);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = fast::clamp(((_292.fa_shadow_cfg.w * _348) * 0.25) / _292.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            float2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            float2 param_5 = _397.xy + (_542 * _292.fa_shadow_bias.zw);\n            float4 param_6 = _292.fa_shadow_rect[ci];\n            float _553 = fa_shadow_depth(param_5, param_6, fa_full_shadow_smp, fa_full_shadow_tex);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_469 - (sum / cnt), 0.0) * _348) * _292.fa_shadow_cfg.w) / _292.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        float2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _397.xy + (_616 * _292.fa_shadow_bias.zw);\n        float4 param_11 = _292.fa_shadow_rect[ci];\n        float _627 = fa_shadow_depth(param_10, param_11, fa_full_shadow_smp, fa_full_shadow_tex);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    if (_649.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _660 = int(_292.fa_shadow_cfg.x + 0.5);\n    if (_660 < 1)\n    {\n        return 1.0;\n    }\n    float _677 = dot(world - _292.fa_shadow_eye.xyz, _292.fa_shadow_fwd.xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param, _292))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > _292.fa_shadow_split.x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > _292.fa_shadow_split.y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > _292.fa_shadow_split.z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex);\n        s = _744;\n        if (_744 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_292.fa_shadow_cfg.y > 0.0)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5, _292);\n        }\n        else\n        {\n            _769 = _292.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _788 = _292.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _292) - _769, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _799 = fast::clamp((_677 - (fa_shadow_split_at(param_7, _292) - _788)) / _788, 0.0, 1.0);\n        if (_799 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex);\n                s2 = _820;\n                if (_820 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float3 _1214 = _859.direction;\n    float3 _1209 = _859.color;\n    float _1211 = _859.shadow;\n    int _1219 = _859.type;\n    if ((_1219 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1214;\n        float _875 = fa_shadow(param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n        _1211 = _875;\n        _1209 *= _875;\n    }\n    return LightSample{ _1214, _1209, _859.attenuation, _1211, _859._distance, _1219 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _649)\n{\n    bool _888 = _649.fa_fog.w > 0.0;\n    bool _896;\n    if (!_888)\n    {\n        _896 = _649.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        float3 _904 = world_pos - _649.fa_camera_pos.xyz;\n        float _911 = dot(_904, _649.fa_fog_c.xyz);\n        bool _915 = _649.fa_fog_c.w > 0.5;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - _649.fa_fog_b.x;\n        if (_928 > 0.0)\n        {\n            float _937 = _649.fa_fog.w * _928;\n            float tau = _937 * _937;\n            if (_649.fa_fog_b.y > 0.0)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (_649.fa_fog_c.y * _911);\n                }\n                else\n                {\n                    _953 = _649.fa_camera_pos.y;\n                }\n                float _974 = mix(_953, world_pos.y, fast::clamp(_649.fa_fog_b.x / _916, 0.0, 1.0));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - _649.fa_fog_b.z;\n                float _988 = world_pos.y - _649.fa_fog_b.z;\n                bool _991 = _983 <= 0.0;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = _649.fa_fog_b.y;\n                }\n                else\n                {\n                    _999 = _649.fa_fog_b.y * exp(-fast::min(_649.fa_fog_b.w * _983, 80.0));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = _649.fa_fog_b.y * _983;\n                }\n                else\n                {\n                    _1027 = (_649.fa_fog_b.y * (1.0 - exp(-fast::min(_649.fa_fog_b.w * _983, 80.0)))) / _649.fa_fog_b.w;\n                }\n                bool _1052 = _988 <= 0.0;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = _649.fa_fog_b.y * _988;\n                }\n                else\n                {\n                    _1060 = (_649.fa_fog_b.y * (1.0 - exp(-fast::min(_649.fa_fog_b.w * _988, 80.0)))) / _649.fa_fog_b.w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * fast::max(_1087, 0.0));\n            }\n            result = mix(result, _649.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649, thread float3& v_normal, constant fa_material& _1132, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1125 = fast::normalize(v_normal);\n    float3 lit = _649.fa_ambient.xyz * _1132.base.xyz;\n    for (int i = 0; i < fa_light_count(_649); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1125;\n        float4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3, fa_full_light_tex, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n        lit += ((_1132.base.xyz * _1157.color) * fast::max(dot(_1125, _1157.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1180 = fa_apply_fog(param_4, param_5, _649);\n    fa_frag_color = float4(_1180, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _649 [[buffer(1)]], constant fa_material& _1132 [[buffer(5)]], constant fa_shadows& _292 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], sampler fa_full_shadow_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_full_light_tex, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649, in.v_normal, _1132, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _71)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_71.fa_joint_rows[_61] * weights[i]);\n        r1 += (_71.fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71.fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_shadow_coord(thread const float3& world)\n{\n    return float4(world, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& v_shadow, thread float4& gl_Position, constant fa_mesh_vs_params& _247)\n{\n    float3 param = fa_position;\n    float3 _227 = fa_world_position(param, fa_model);\n    v_pos = _227;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    float3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = _247.fa_view_proj * float4(_227, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _247 [[buffer(0)]], constant fa_skin& _71 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _71);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.v_shadow, out.gl_Position, _247);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _649)\n{\n    return min(int(_649.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    int param = li * 4;\n    float4 _110 = fa_light_texel(param, fa_full_light_tex, fa_full_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _117 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float _122 = _117.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _130 = _122 < 0.5;\n    float3 l;\n    if (_130)\n    {\n        l = fast::normalize(_110.xyz);\n    }\n    else\n    {\n        float3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / float3(fast::max(_144, 9.9999997473787516355514526367188e-05));\n        float _159 = _144 / fast::max(_110.w, 0.001000000047497451305389404296875);\n        float _165 = fast::clamp(1.0 - (_159 * _159), 0.0, 1.0);\n        atten = _165 * _165;\n        if (_122 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _180 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            float4 _197 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5)\n            {\n                cos_inner = mix(_190, 1.0, 0.25);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, fast::normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _117.xyz * atten, atten, 1.0, dist, _230 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _292)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = _292.fa_shadow_split.x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = _292.fa_shadow_split.y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = _292.fa_shadow_split.z;\n            }\n            else\n            {\n                _308 = _292.fa_shadow_split.w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_full_shadow_smp, texture2d<float> fa_full_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex)\n{\n    float _348 = fast::max(_292.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _353 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _359 = sqrt(1.0 - (_353 * _353));\n    float _367 = fast::min(_359 / fast::max(_353, 0.20000000298023223876953125), 4.0);\n    float _372;\n    if (_292.fa_shadow_bias.y > 0.0)\n    {\n        _372 = _292.fa_shadow_bias.y;\n    }\n    else\n    {\n        _372 = 1.5 * _292.fa_shadow_info[ci].x;\n    }\n    float4 _397 = _292.fa_shadow_mat[ci] * float4(world + (n * (_372 * _359)), 1.0);\n    float _404 = _397.x;\n    bool _407 = _404 < _292.fa_shadow_rect[ci].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > _292.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < _292.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > _292.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0;\n    }\n    float _450;\n    if (_292.fa_shadow_bias.x > 0.0)\n    {\n        _450 = _292.fa_shadow_bias.x;\n    }\n    else\n    {\n        _450 = 1.5 * _292.fa_shadow_info[ci].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0 + (0.5 * _367))) / _348);\n    float _478 = ((_292.fa_shadow_info[ci].x * fast::min(_367, 3.0)) * 0.5) / _348;\n    int _487 = int(_292.fa_shadow_cfg.z + 0.5);\n    if (_487 == 1)\n    {\n        float2 param = _397.xy;\n        float4 param_1 = _292.fa_shadow_rect[ci];\n        float _498 = fa_shadow_depth(param, param_1, fa_full_shadow_smp, fa_full_shadow_tex);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = fast::clamp(((_292.fa_shadow_cfg.w * _348) * 0.25) / _292.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            float2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            float2 param_5 = _397.xy + (_542 * _292.fa_shadow_bias.zw);\n            float4 param_6 = _292.fa_shadow_rect[ci];\n            float _553 = fa_shadow_depth(param_5, param_6, fa_full_shadow_smp, fa_full_shadow_tex);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_469 - (sum / cnt), 0.0) * _348) * _292.fa_shadow_cfg.w) / _292.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        float2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _397.xy + (_616 * _292.fa_shadow_bias.zw);\n        float4 param_11 = _292.fa_shadow_rect[ci];\n        float _627 = fa_shadow_depth(param_10, param_11, fa_full_shadow_smp, fa_full_shadow_tex);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    if (_649.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _660 = int(_292.fa_shadow_cfg.x + 0.5);\n    if (_660 < 1)\n    {\n        return 1.0;\n    }\n    float _677 = dot(world - _292.fa_shadow_eye.xyz, _292.fa_shadow_fwd.xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param, _292))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > _292.fa_shadow_split.x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > _292.fa_shadow_split.y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > _292.fa_shadow_split.z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex);\n        s = _744;\n        if (_744 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_292.fa_shadow_cfg.y > 0.0)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5, _292);\n        }\n        else\n        {\n            _769 = _292.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _788 = _292.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _292) - _769, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _799 = fast::clamp((_677 - (fa_shadow_split_at(param_7, _292) - _788)) / _788, 0.0, 1.0);\n        if (_799 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex);\n                s2 = _820;\n                if (_820 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float3 _1214 = _859.direction;\n    float3 _1209 = _859.color;\n    float _1211 = _859.shadow;\n    int _1219 = _859.type;\n    if ((_1219 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1214;\n        float _875 = fa_shadow(param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n        _1211 = _875;\n        _1209 *= _875;\n    }\n    return LightSample{ _1214, _1209, _859.attenuation, _1211, _859._distance, _1219 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _649)\n{\n    bool _888 = _649.fa_fog.w > 0.0;\n    bool _896;\n    if (!_888)\n    {\n        _896 = _649.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        float3 _904 = world_pos - _649.fa_camera_pos.xyz;\n        float _911 = dot(_904, _649.fa_fog_c.xyz);\n        bool _915 = _649.fa_fog_c.w > 0.5;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - _649.fa_fog_b.x;\n        if (_928 > 0.0)\n        {\n            float _937 = _649.fa_fog.w * _928;\n            float tau = _937 * _937;\n            if (_649.fa_fog_b.y > 0.0)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (_649.fa_fog_c.y * _911);\n                }\n                else\n                {\n                    _953 = _649.fa_camera_pos.y;\n                }\n                float _974 = mix(_953, world_pos.y, fast::clamp(_649.fa_fog_b.x / _916, 0.0, 1.0));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - _649.fa_fog_b.z;\n                float _988 = world_pos.y - _649.fa_fog_b.z;\n                bool _991 = _983 <= 0.0;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = _649.fa_fog_b.y;\n                }\n                else\n                {\n                    _999 = _649.fa_fog_b.y * exp(-fast::min(_649.fa_fog_b.w * _983, 80.0));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = _649.fa_fog_b.y * _983;\n                }\n                else\n                {\n                    _1027 = (_649.fa_fog_b.y * (1.0 - exp(-fast::min(_649.fa_fog_b.w * _983, 80.0)))) / _649.fa_fog_b.w;\n                }\n                bool _1052 = _988 <= 0.0;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = _649.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = _649.fa_fog_b.y * _988;\n                }\n                else\n                {\n                    _1060 = (_649.fa_fog_b.y * (1.0 - exp(-fast::min(_649.fa_fog_b.w * _988, 80.0)))) / _649.fa_fog_b.w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * fast::max(_1087, 0.0));\n            }\n            result = mix(result, _649.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _292, texture2d<float> fa_full_shadow_tex, constant fa_mesh_fs_params& _649, thread float3& v_normal, constant fa_material& _1132, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1125 = fast::normalize(v_normal);\n    float3 lit = _649.fa_ambient.xyz * _1132.base.xyz;\n    for (int i = 0; i < fa_light_count(_649); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1125;\n        float4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3, fa_full_light_tex, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649);\n        lit += ((_1132.base.xyz * _1157.color) * fast::max(dot(_1125, _1157.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1180 = fa_apply_fog(param_4, param_5, _649);\n    fa_frag_color = float4(_1180, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _649 [[buffer(1)]], constant fa_material& _1132 [[buffer(5)]], constant fa_shadows& _292 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], sampler fa_full_shadow_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_full_light_tex, fa_full_shadow_smp, gl_FragCoord, _292, fa_full_shadow_tex, _649, in.v_normal, _1132, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
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
