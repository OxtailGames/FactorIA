{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "988cfc1c160a2406bf9dc799340ab0aac9eeed94208cd8193e37bfb0d2577a5b",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _106)\n{\n    return min(int(_106.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _106)\n{\n    return li * ((_106.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    return fa_full_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_full_light_atlas.get_width(), fa_full_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_full_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10)\n    {\n        _206 = precise::atan2(_195, _191) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _206 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_206 - floor(_206)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_full_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _240 = fa_light_base(param, _106);\n    bool _245 = _106.fa_counts.y > 4.5;\n    int param_1 = _240;\n    float4 _249 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    int param_2 = _240 + 1;\n    float4 _255 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n    float _259 = _255.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _271 = _245 && (_259 > 2.5);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5;\n    float3 l;\n    if (_274)\n    {\n        l = fast::normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            float4 _289 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            if (_289.z > 0.5)\n            {\n                int param_4 = _240 + 4;\n                float4 _300 = fa_light_texel(param_4, fa_full_light_tex, fa_full_shadow_smp);\n                int param_5 = _240 + 5;\n                float4 _306 = fa_light_texel(param_5, fa_full_light_tex, fa_full_shadow_smp);\n                float2 param_6 = _289.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_full_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / float3(fast::max(_340, 9.9999997473787516355514526367188e-05));\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_full_light_tex, fa_full_shadow_smp).w, 0.0);\n        }\n        float _372 = reach / fast::max(_249.w, 0.001000000047497451305389404296875);\n        float _378 = fast::clamp(1.0 - (_372 * _372), 0.0, 1.0);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5;\n        if ((_259 > 1.5) && _386)\n        {\n            int param_9 = _240 + 2;\n            float4 _395 = fa_light_texel(param_9, fa_full_light_tex, fa_full_shadow_smp);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            float4 _411 = fa_light_texel(param_10, fa_full_light_tex, fa_full_shadow_smp);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5)\n            {\n                cos_inner = mix(_405, 1.0, 0.25);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, fast::normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            float4 _436 = fa_light_texel(param_11, fa_full_light_tex, fa_full_shadow_smp);\n            int param_12 = _240 + 7;\n            float4 _441 = fa_light_texel(param_12, fa_full_light_tex, fa_full_shadow_smp);\n            bool _444 = _436.z > 0.5;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                float4 _458 = fa_light_texel(param_13, fa_full_light_tex, fa_full_shadow_smp);\n                float3 _462 = fast::normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                float4 _467 = fa_light_texel(param_14, fa_full_light_tex, fa_full_shadow_smp);\n                int param_15 = _240 + 5;\n                float4 _472 = fa_light_texel(param_15, fa_full_light_tex, fa_full_shadow_smp);\n                if (_444)\n                {\n                    float3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5 / fast::max(dot(_480, _462) * (sqrt(fast::max(1.0 - (_487 * _487), 0.0)) / fast::max(_487, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _436.xy;\n                    float2 param_17 = float2(0.5 + (dot(_480, _467.xyz) * _503), 0.5 - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_full_light_atlas, fa_env_smp);\n                }\n                if (_441.z > 0.5)\n                {\n                    float2 param_18 = _441.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _462;\n                    float3 param_21 = _467.xyz;\n                    float3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_full_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5) && (_259 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _1529, atten, 1.0, dist, _572 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _637)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = _637.fa_shadow_split.x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = _637.fa_shadow_split.y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = _637.fa_shadow_split.z;\n            }\n            else\n            {\n                _651 = _637.fa_shadow_split.w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_full_shadow_smp, texture2d<float> fa_full_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    float _690 = fast::max(_637.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _695 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _701 = sqrt(1.0 - (_695 * _695));\n    float _709 = fast::min(_701 / fast::max(_695, 0.20000000298023223876953125), 4.0);\n    float _714;\n    if (_637.fa_shadow_bias.y > 0.0)\n    {\n        _714 = _637.fa_shadow_bias.y;\n    }\n    else\n    {\n        _714 = 1.5 * _637.fa_shadow_info[ci].x;\n    }\n    float4 _739 = _637.fa_shadow_mat[ci] * float4(world + (n * (_714 * _701)), 1.0);\n    float _746 = _739.x;\n    bool _749 = _746 < _637.fa_shadow_rect[ci].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > _637.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < _637.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > _637.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0;\n    }\n    float _791;\n    if (_637.fa_shadow_bias.x > 0.0)\n    {\n        _791 = _637.fa_shadow_bias.x;\n    }\n    else\n    {\n        _791 = 1.5 * _637.fa_shadow_info[ci].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0 + (0.5 * _709))) / _690);\n    float _819 = ((_637.fa_shadow_info[ci].x * fast::min(_709, 3.0)) * 0.5) / _690;\n    int _828 = int(_637.fa_shadow_cfg.z + 0.5);\n    if (_828 == 1)\n    {\n        float2 param = _739.xy;\n        float4 param_1 = _637.fa_shadow_rect[ci];\n        float _839 = fa_shadow_depth(param, param_1, fa_full_shadow_smp, fa_full_shadow_tex);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = fast::clamp(((_637.fa_shadow_cfg.w * _690) * 0.25) / _637.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            float2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            float2 param_5 = _739.xy + (_883 * _637.fa_shadow_bias.zw);\n            float4 param_6 = _637.fa_shadow_rect[ci];\n            float _894 = fa_shadow_depth(param_5, param_6, fa_full_shadow_smp, fa_full_shadow_tex);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_810 - (sum / cnt), 0.0) * _690) * _637.fa_shadow_cfg.w) / _637.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        float2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _739.xy + (_957 * _637.fa_shadow_bias.zw);\n        float4 param_11 = _637.fa_shadow_rect[ci];\n        float _968 = fa_shadow_depth(param_10, param_11, fa_full_shadow_smp, fa_full_shadow_tex);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _106, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    if (_106.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _998 = int(_637.fa_shadow_cfg.x + 0.5);\n    if (_998 < 1)\n    {\n        return 1.0;\n    }\n    float _1013 = dot(world - _637.fa_shadow_eye.xyz, _637.fa_shadow_fwd.xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param, _637))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > _637.fa_shadow_split.x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > _637.fa_shadow_split.y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > _637.fa_shadow_split.z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n        s = _1080;\n        if (_1080 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_637.fa_shadow_cfg.y > 0.0)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5, _637);\n        }\n        else\n        {\n            _1105 = _637.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1124 = _637.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _637) - _1105, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1135 = fast::clamp((_1013 - (fa_shadow_split_at(param_7, _637) - _1124)) / _1124, 0.0, 1.0);\n        if (_1135 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n                s2 = _1156;\n                if (_1156 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _106, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _106, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1, _106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4, _106, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    return LightSample{ _1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _106)\n{\n    bool _1224 = _106.fa_fog.w > 0.0;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = _106.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        float3 _1239 = world_pos - _106.fa_camera_pos.xyz;\n        float _1246 = dot(_1239, _106.fa_fog_c.xyz);\n        bool _1250 = _106.fa_fog_c.w > 0.5;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - _106.fa_fog_b.x;\n        if (_1263 > 0.0)\n        {\n            float _1272 = _106.fa_fog.w * _1263;\n            float tau = _1272 * _1272;\n            if (_106.fa_fog_b.y > 0.0)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (_106.fa_fog_c.y * _1246);\n                }\n                else\n                {\n                    _1288 = _106.fa_camera_pos.y;\n                }\n                float _1309 = mix(_1288, world_pos.y, fast::clamp(_106.fa_fog_b.x / _1251, 0.0, 1.0));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - _106.fa_fog_b.z;\n                float _1323 = world_pos.y - _106.fa_fog_b.z;\n                bool _1326 = _1318 <= 0.0;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _106.fa_fog_b.y;\n                }\n                else\n                {\n                    _1334 = _106.fa_fog_b.y * exp(-fast::min(_106.fa_fog_b.w * _1318, 80.0));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _106.fa_fog_b.y * _1318;\n                }\n                else\n                {\n                    _1362 = (_106.fa_fog_b.y * (1.0 - exp(-fast::min(_106.fa_fog_b.w * _1318, 80.0)))) / _106.fa_fog_b.w;\n                }\n                bool _1387 = _1323 <= 0.0;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = _106.fa_fog_b.y * _1323;\n                }\n                else\n                {\n                    _1395 = (_106.fa_fog_b.y * (1.0 - exp(-fast::min(_106.fa_fog_b.w * _1323, 80.0)))) / _106.fa_fog_b.w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * fast::max(_1422, 0.0));\n            }\n            result = mix(result, _106.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex, thread float3& v_normal, constant fa_material& _1467, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1460 = fast::normalize(v_normal);\n    float3 lit = _106.fa_ambient.xyz * _1467.base.xyz;\n    for (int i = 0; i < fa_light_count(_106); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1460;\n        float4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3, _106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _637, fa_full_shadow_tex);\n        lit += ((_1467.base.xyz * _1492.color) * fast::max(dot(_1460, _1492.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1515 = fa_apply_fog(param_4, param_5, _106);\n    fa_frag_color = float4(_1515, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _106 [[buffer(1)]], constant fa_material& _1467 [[buffer(5)]], constant fa_shadows& _637 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], texture2d<float> fa_full_light_atlas [[texture(2)]], sampler fa_full_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    fa_user_main(_106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _637, fa_full_shadow_tex, in.v_normal, _1467, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 2,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _106)\n{\n    return min(int(_106.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _106)\n{\n    return li * ((_106.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    return fa_full_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_full_light_atlas.get_width(), fa_full_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_full_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_full_light_atlas, sampler fa_env_smp)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10)\n    {\n        _206 = precise::atan2(_195, _191) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _206 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_206 - floor(_206)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_full_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _240 = fa_light_base(param, _106);\n    bool _245 = _106.fa_counts.y > 4.5;\n    int param_1 = _240;\n    float4 _249 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    int param_2 = _240 + 1;\n    float4 _255 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n    float _259 = _255.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _271 = _245 && (_259 > 2.5);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5;\n    float3 l;\n    if (_274)\n    {\n        l = fast::normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            float4 _289 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            if (_289.z > 0.5)\n            {\n                int param_4 = _240 + 4;\n                float4 _300 = fa_light_texel(param_4, fa_full_light_tex, fa_full_shadow_smp);\n                int param_5 = _240 + 5;\n                float4 _306 = fa_light_texel(param_5, fa_full_light_tex, fa_full_shadow_smp);\n                float2 param_6 = _289.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_full_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / float3(fast::max(_340, 9.9999997473787516355514526367188e-05));\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_full_light_tex, fa_full_shadow_smp).w, 0.0);\n        }\n        float _372 = reach / fast::max(_249.w, 0.001000000047497451305389404296875);\n        float _378 = fast::clamp(1.0 - (_372 * _372), 0.0, 1.0);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5;\n        if ((_259 > 1.5) && _386)\n        {\n            int param_9 = _240 + 2;\n            float4 _395 = fa_light_texel(param_9, fa_full_light_tex, fa_full_shadow_smp);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            float4 _411 = fa_light_texel(param_10, fa_full_light_tex, fa_full_shadow_smp);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5)\n            {\n                cos_inner = mix(_405, 1.0, 0.25);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, fast::normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            float4 _436 = fa_light_texel(param_11, fa_full_light_tex, fa_full_shadow_smp);\n            int param_12 = _240 + 7;\n            float4 _441 = fa_light_texel(param_12, fa_full_light_tex, fa_full_shadow_smp);\n            bool _444 = _436.z > 0.5;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                float4 _458 = fa_light_texel(param_13, fa_full_light_tex, fa_full_shadow_smp);\n                float3 _462 = fast::normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                float4 _467 = fa_light_texel(param_14, fa_full_light_tex, fa_full_shadow_smp);\n                int param_15 = _240 + 5;\n                float4 _472 = fa_light_texel(param_15, fa_full_light_tex, fa_full_shadow_smp);\n                if (_444)\n                {\n                    float3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5 / fast::max(dot(_480, _462) * (sqrt(fast::max(1.0 - (_487 * _487), 0.0)) / fast::max(_487, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _436.xy;\n                    float2 param_17 = float2(0.5 + (dot(_480, _467.xyz) * _503), 0.5 - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_full_light_atlas, fa_env_smp);\n                }\n                if (_441.z > 0.5)\n                {\n                    float2 param_18 = _441.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _462;\n                    float3 param_21 = _467.xyz;\n                    float3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_full_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5) && (_259 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _1529, atten, 1.0, dist, _572 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _637)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = _637.fa_shadow_split.x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = _637.fa_shadow_split.y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = _637.fa_shadow_split.z;\n            }\n            else\n            {\n                _651 = _637.fa_shadow_split.w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_full_shadow_smp, texture2d<float> fa_full_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_full_shadow_tex.sample(fa_full_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    float _690 = fast::max(_637.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _695 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _701 = sqrt(1.0 - (_695 * _695));\n    float _709 = fast::min(_701 / fast::max(_695, 0.20000000298023223876953125), 4.0);\n    float _714;\n    if (_637.fa_shadow_bias.y > 0.0)\n    {\n        _714 = _637.fa_shadow_bias.y;\n    }\n    else\n    {\n        _714 = 1.5 * _637.fa_shadow_info[ci].x;\n    }\n    float4 _739 = _637.fa_shadow_mat[ci] * float4(world + (n * (_714 * _701)), 1.0);\n    float _746 = _739.x;\n    bool _749 = _746 < _637.fa_shadow_rect[ci].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > _637.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < _637.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > _637.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0;\n    }\n    float _791;\n    if (_637.fa_shadow_bias.x > 0.0)\n    {\n        _791 = _637.fa_shadow_bias.x;\n    }\n    else\n    {\n        _791 = 1.5 * _637.fa_shadow_info[ci].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0 + (0.5 * _709))) / _690);\n    float _819 = ((_637.fa_shadow_info[ci].x * fast::min(_709, 3.0)) * 0.5) / _690;\n    int _828 = int(_637.fa_shadow_cfg.z + 0.5);\n    if (_828 == 1)\n    {\n        float2 param = _739.xy;\n        float4 param_1 = _637.fa_shadow_rect[ci];\n        float _839 = fa_shadow_depth(param, param_1, fa_full_shadow_smp, fa_full_shadow_tex);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = fast::clamp(((_637.fa_shadow_cfg.w * _690) * 0.25) / _637.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            float2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            float2 param_5 = _739.xy + (_883 * _637.fa_shadow_bias.zw);\n            float4 param_6 = _637.fa_shadow_rect[ci];\n            float _894 = fa_shadow_depth(param_5, param_6, fa_full_shadow_smp, fa_full_shadow_tex);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_810 - (sum / cnt), 0.0) * _690) * _637.fa_shadow_cfg.w) / _637.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        float2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _739.xy + (_957 * _637.fa_shadow_bias.zw);\n        float4 param_11 = _637.fa_shadow_rect[ci];\n        float _968 = fa_shadow_depth(param_10, param_11, fa_full_shadow_smp, fa_full_shadow_tex);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _106, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    if (_106.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _998 = int(_637.fa_shadow_cfg.x + 0.5);\n    if (_998 < 1)\n    {\n        return 1.0;\n    }\n    float _1013 = dot(world - _637.fa_shadow_eye.xyz, _637.fa_shadow_fwd.xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param, _637))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > _637.fa_shadow_split.x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > _637.fa_shadow_split.y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > _637.fa_shadow_split.z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n        s = _1080;\n        if (_1080 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_637.fa_shadow_cfg.y > 0.0)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5, _637);\n        }\n        else\n        {\n            _1105 = _637.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1124 = _637.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _637) - _1105, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1135 = fast::clamp((_1013 - (fa_shadow_split_at(param_7, _637) - _1124)) / _1124, 0.0, 1.0);\n        if (_1135 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n                s2 = _1156;\n                if (_1156 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _106, sampler fa_full_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    float3 param = coord.xyz / float3(coord.w);\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _106, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1, _106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4, _106, fa_full_shadow_smp, gl_FragCoord, _637, fa_full_shadow_tex);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    return LightSample{ _1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _106)\n{\n    bool _1224 = _106.fa_fog.w > 0.0;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = _106.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        float3 _1239 = world_pos - _106.fa_camera_pos.xyz;\n        float _1246 = dot(_1239, _106.fa_fog_c.xyz);\n        bool _1250 = _106.fa_fog_c.w > 0.5;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - _106.fa_fog_b.x;\n        if (_1263 > 0.0)\n        {\n            float _1272 = _106.fa_fog.w * _1263;\n            float tau = _1272 * _1272;\n            if (_106.fa_fog_b.y > 0.0)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (_106.fa_fog_c.y * _1246);\n                }\n                else\n                {\n                    _1288 = _106.fa_camera_pos.y;\n                }\n                float _1309 = mix(_1288, world_pos.y, fast::clamp(_106.fa_fog_b.x / _1251, 0.0, 1.0));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - _106.fa_fog_b.z;\n                float _1323 = world_pos.y - _106.fa_fog_b.z;\n                bool _1326 = _1318 <= 0.0;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _106.fa_fog_b.y;\n                }\n                else\n                {\n                    _1334 = _106.fa_fog_b.y * exp(-fast::min(_106.fa_fog_b.w * _1318, 80.0));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _106.fa_fog_b.y * _1318;\n                }\n                else\n                {\n                    _1362 = (_106.fa_fog_b.y * (1.0 - exp(-fast::min(_106.fa_fog_b.w * _1318, 80.0)))) / _106.fa_fog_b.w;\n                }\n                bool _1387 = _1323 <= 0.0;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _106.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = _106.fa_fog_b.y * _1323;\n                }\n                else\n                {\n                    _1395 = (_106.fa_fog_b.y * (1.0 - exp(-fast::min(_106.fa_fog_b.w * _1323, 80.0)))) / _106.fa_fog_b.w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * fast::max(_1422, 0.0));\n            }\n            result = mix(result, _106.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _106, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, texture2d<float> fa_full_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _637, texture2d<float> fa_full_shadow_tex, thread float3& v_normal, constant fa_material& _1467, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _1460 = fast::normalize(v_normal);\n    float3 lit = _106.fa_ambient.xyz * _1467.base.xyz;\n    for (int i = 0; i < fa_light_count(_106); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _1460;\n        float4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3, _106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _637, fa_full_shadow_tex);\n        lit += ((_1467.base.xyz * _1492.color) * fast::max(dot(_1460, _1492.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _1515 = fa_apply_fog(param_4, param_5, _106);\n    fa_frag_color = float4(_1515, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _106 [[buffer(1)]], constant fa_material& _1467 [[buffer(5)]], constant fa_shadows& _637 [[buffer(7)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], texture2d<float> fa_full_light_atlas [[texture(2)]], sampler fa_full_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    fa_user_main(_106, fa_full_light_tex, fa_full_shadow_smp, fa_full_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _637, fa_full_shadow_tex, in.v_normal, _1467, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 2,
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
