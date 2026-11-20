{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1331 = fa_linear_to_srgb(param);\n        c = _1331;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1339 = fa_srgb_to_linear(param_1);\n            c = _1339;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _149;\n    if (bool(i.front_facing))\n    {\n        _149 = i.world_normal;\n    }\n    else\n    {\n        _149 = -i.world_normal;\n    }\n    float3 _173 = fast::normalize(i.world_tangent.xyz - (_149 * dot(_149, i.world_tangent.xyz)));\n    float3 _201 = fast::normalize(((_173 * m.x) + ((cross(_149, _173) * i.world_tangent.w) * m.y)) + (_149 * m.z));\n    float3 _204;\n    if (bool(i.front_facing))\n    {\n        _204 = _201;\n    }\n    else\n    {\n        _204 = -_201;\n    }\n    return _204;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _745, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _745.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1370 = fa_tex_fix(param_2, param_3);\n    float4 _2070 = base_t;\n    _2070.x = _1370.x;\n    _2070.y = _1370.y;\n    _2070.z = _1370.z;\n    base_t = _2070;\n    float4 _1384 = (_2070 * _745.fa_base_color) * i.vertex_color;\n    float3 _2038 = i.world_normal;\n    if (_745.fa_maps.z > 0.5)\n    {\n        float param_4 = _745.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1416 = fa_tex_fix(param_6, param_7);\n        float3 _1420 = (_1416 * 2.0) - float3(1.0);\n        float2 _1425 = _1420.xy * _745.fa_maps.x;\n        float3 _2078 = _1420;\n        _2078.x = _1425.x;\n        _2078.y = _1425.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2078;\n        _2038 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _745.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1454 = fa_tex_fix(param_12, param_13);\n    float4 _2081 = mrt;\n    _2081.x = _1454.x;\n    _2081.y = _1454.y;\n    _2081.z = _1454.z;\n    mrt = _2081;\n    float param_14 = _745.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1493 = fa_tex_fix(param_16, param_17);\n    float param_18 = _745.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1520 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1384.xyz, _1384.w, _2038, fast::clamp(_745.fa_pbr.x * _1454.z, 0.0, 1.0), fast::clamp(_745.fa_pbr.y * _1454.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_745.fa_maps.y * (_1493.x - 1.0)), _745.fa_emissive.xyz + (_745.fa_model_emissive.xyz * _1520) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _745, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_745.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _745.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1147 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1150 = _1147.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1150 * _1150, exp2((-9.27999973297119140625) * ndv)) * _1150) + _1147.y)) + _1147.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_745.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _745.fa_env_horizon.w)).xyz;\n    }\n    float _1052 = rough * rough;\n    float _1082 = 0.60000002384185791015625 * _1052;\n    return mix(mix(_745.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_745.fa_env_horizon.xyz, _745.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1052)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1082, 0.0500000007450580596923828125 + _1082, d.y))), ((_745.fa_env_sky.xyz + _745.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1052 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1189 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _745, fa_env_tex, fa_env_smp) * ((f0 * _1189.x) + float3(_1189.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _745, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _745, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _221)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _232 = _221.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_232)\n    {\n        l = fast::normalize(_221.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _250 = _221.fa_light_pos[li].xyz - world_pos;\n        float _252 = length(_250);\n        dist = _252;\n        l = _250 / float3(fast::max(_252, 9.9999997473787516355514526367188e-05));\n        float _268 = _252 / fast::max(_221.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _274 = fast::clamp(1.0 - (_268 * _268), 0.0, 1.0);\n        atten = _274 * _274;\n        if (_221.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_221.fa_light_dir[li].w, mix(_221.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_221.fa_light_dir[li].xyz)));\n        }\n    }\n    int _324;\n    if (_232)\n    {\n        _324 = 0;\n    }\n    else\n    {\n        _324 = (_221.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _221.fa_light_color[li].xyz * atten, atten, 1.0, dist, _324 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _386)\n{\n    float _376;\n    if (i == 0)\n    {\n        _376 = _386.fa_shadow_split.x;\n    }\n    else\n    {\n        float _392;\n        if (i == 1)\n        {\n            _392 = _386.fa_shadow_split.y;\n        }\n        else\n        {\n            float _400;\n            if (i == 2)\n            {\n                _400 = _386.fa_shadow_split.z;\n            }\n            else\n            {\n                _400 = _386.fa_shadow_split.w;\n            }\n            _392 = _400;\n        }\n        _376 = _392;\n    }\n    return _376;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _364 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_364), sin(_364)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _444 = fast::max(_386.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _449 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _455 = sqrt(1.0 - (_449 * _449));\n    float _463 = fast::min(_455 / fast::max(_449, 0.20000000298023223876953125), 4.0);\n    float _468;\n    if (_386.fa_shadow_bias.y > 0.0)\n    {\n        _468 = _386.fa_shadow_bias.y;\n    }\n    else\n    {\n        _468 = 1.5 * _386.fa_shadow_info[ci].x;\n    }\n    float4 _493 = _386.fa_shadow_mat[ci] * float4(world + (n * (_468 * _455)), 1.0);\n    float _500 = _493.x;\n    bool _503 = _500 < _386.fa_shadow_rect[ci].x;\n    bool _512;\n    if (!_503)\n    {\n        _512 = _500 > _386.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _512 = _503;\n    }\n    bool _521;\n    if (!_512)\n    {\n        _521 = _493.y < _386.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _521 = _512;\n    }\n    bool _530;\n    if (!_521)\n    {\n        _530 = _493.y > _386.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _530 = _521;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _493.z > 1.0;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return -1.0;\n    }\n    float _546;\n    if (_386.fa_shadow_bias.x > 0.0)\n    {\n        _546 = _386.fa_shadow_bias.x;\n    }\n    else\n    {\n        _546 = 1.5 * _386.fa_shadow_info[ci].x;\n    }\n    float _565 = _493.z - ((_546 * (1.0 + (0.5 * _463))) / _444);\n    float _574 = ((_386.fa_shadow_info[ci].x * fast::min(_463, 3.0)) * 0.5) / _444;\n    int _583 = int(_386.fa_shadow_cfg.z + 0.5);\n    if (_583 == 1)\n    {\n        float2 param = _493.xy;\n        float4 param_1 = _386.fa_shadow_rect[ci];\n        float _594 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_565 <= _594);\n    }\n    float _601 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _604 = _583 == 2;\n    if (_604)\n    {\n        float _618 = fast::clamp(((_386.fa_shadow_cfg.w * _444) * 0.25) / _386.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _601;\n            float2 _638 = fa_shadow_vogel(param_2, param_3, param_4) * _618;\n            float2 param_5 = _493.xy + (_638 * _386.fa_shadow_bias.zw);\n            float4 param_6 = _386.fa_shadow_rect[ci];\n            float _649 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_649 < (_565 - (length(_638) * _574)))\n            {\n                sum += _649;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_565 - (sum / cnt), 0.0) * _444) * _386.fa_shadow_cfg.w) / _386.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _693 = _604 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _693; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _693;\n        float param_9 = _601;\n        float2 _712 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _493.xy + (_712 * _386.fa_shadow_bias.zw);\n        float4 param_11 = _386.fa_shadow_rect[ci];\n        float _723 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_565 - (length(_712) * _574)) <= _723);\n    }\n    return lit / float(_693);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745)\n{\n    if (_745.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _756 = int(_386.fa_shadow_cfg.x + 0.5);\n    if (_756 < 1)\n    {\n        return 1.0;\n    }\n    float _772 = dot(world - _386.fa_shadow_eye.xyz, _386.fa_shadow_fwd.xyz);\n    int param = _756 - 1;\n    if (_772 > fa_shadow_split_at(param, _386))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _784 = _756 > 1;\n    bool _791;\n    if (_784)\n    {\n        _791 = _772 > _386.fa_shadow_split.x;\n    }\n    else\n    {\n        _791 = _784;\n    }\n    if (_791)\n    {\n        ci = 1;\n    }\n    bool _795 = _756 > 2;\n    bool _802;\n    if (_795)\n    {\n        _802 = _772 > _386.fa_shadow_split.y;\n    }\n    else\n    {\n        _802 = _795;\n    }\n    if (_802)\n    {\n        ci = 2;\n    }\n    bool _806 = _756 > 3;\n    bool _813;\n    if (_806)\n    {\n        _813 = _772 > _386.fa_shadow_split.z;\n    }\n    else\n    {\n        _813 = _806;\n    }\n    if (_813)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _756)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _839 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp);\n        s = _839;\n        if (_839 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_386.fa_shadow_cfg.y > 0.0)\n    {\n        float _864;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _864 = fa_shadow_split_at(param_5, _386);\n        }\n        else\n        {\n            _864 = _386.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _883 = _386.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _386) - _864, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _894 = fast::clamp((_772 - (fa_shadow_split_at(param_7, _386) - _883)) / _883, 0.0, 1.0);\n        if (_894 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _756)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _915 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp);\n                s2 = _915;\n                if (_915 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _894);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _221, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1244 = fa_light_sample(param, param_1, _221);\n    float3 _2023 = _1244.direction;\n    float3 _2018 = _1244.color;\n    float _2025 = _1244.attenuation;\n    float _2020 = _1244.shadow;\n    int _2028 = _1244.type;\n    if ((_2028 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2023;\n        float _1258 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745, fa_world_pos);\n        _2020 = _1258;\n        _2018 = _221.fa_light_color[li].xyz * (_2025 * _1258);\n    }\n    return LightSample{ _2023, _2018, _2025, _2020, _1244._distance, _2028 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _386)\n{\n    if (_386.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _939 = int(_386.fa_shadow_cfg.x + 0.5);\n    float _949 = dot(world - _386.fa_shadow_eye.xyz, _386.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _954 = _939 > 0;\n    bool _963;\n    if (_954)\n    {\n        int param = _939 - 1;\n        _963 = _949 <= fa_shadow_split_at(param, _386);\n    }\n    else\n    {\n        _963 = _954;\n    }\n    if (_963)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _970 = _939 > 1;\n        bool _977;\n        if (_970)\n        {\n            _977 = _949 > _386.fa_shadow_split.x;\n        }\n        else\n        {\n            _977 = _970;\n        }\n        if (_977)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _983 = _939 > 2;\n        bool _990;\n        if (_983)\n        {\n            _990 = _949 > _386.fa_shadow_split.y;\n        }\n        else\n        {\n            _990 = _983;\n        }\n        if (_990)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _996 = _939 > 3;\n        bool _1003;\n        if (_996)\n        {\n            _1003 = _949 > _386.fa_shadow_split.z;\n        }\n        else\n        {\n            _1003 = _996;\n        }\n        if (_1003)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _745 [[buffer(1)]], constant fa_lights& _221 [[buffer(2)]], constant fa_shadows& _386 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1901 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1901 = -_1901;\n    }\n    float3 _1563 = fast::normalize(_745.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n    Surface _1568 = fa_standard_surface(param, _745, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1940 = _1568.albedo;\n    float _1941 = _1568.alpha;\n    float3 _1942 = _1568.normal;\n    float _1943 = _1568.metallic;\n    float _1944 = _1568.roughness;\n    float _1945 = _1568.occlusion;\n    float3 _1946 = _1568.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n    Surface param_2 = _1568;\n    surface(param_1, param_2);\n    _1940 = param_2.albedo;\n    _1941 = param_2.alpha;\n    _1942 = param_2.normal;\n    _1943 = param_2.metallic;\n    _1944 = param_2.roughness;\n    _1945 = param_2.occlusion;\n    _1946 = param_2.emission;\n    float3 result;\n    if (_745.fa_emissive.w > 0.5)\n    {\n        result = _1940;\n    }\n    else\n    {\n        float3 _1589 = _1942;\n        float3 _1590 = fast::normalize(_1589);\n        _1942 = _1590;\n        float3 param_3 = _1590;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _1940, _1941, _1942, _1943, _1944, _1945, _1946 };\n        float3 param_6 = fa_ambient_light(param_3, _745, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_4, param_5, param_6, _745, fa_env_tex, fa_env_smp);\n        int _1610 = int(_745.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1610)\n            {\n                break;\n            }\n            int param_7 = li;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _1901;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _1940, _1941, _1942, _1943, _1944, _1945, _1946 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, _221, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745, in.fa_world_pos);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    float3 _1649 = result;\n    float3 _1650 = _1649 + _1946;\n    result = _1650;\n    float3 param_13 = _1650;\n    float3 param_14 = in.fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14, _386);\n    bool _1659 = _745.fa_fog.w > 0.0;\n    bool _1667;\n    if (!_1659)\n    {\n        _1667 = _745.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1667 = _1659;\n    }\n    if (_1667)\n    {\n        float3 _1676 = in.fa_world_pos - _745.fa_camera_pos.xyz;\n        float _1683 = dot(_1676, _745.fa_fog_c.xyz);\n        bool _1687 = _745.fa_fog_c.w > 0.5;\n        float _1688;\n        if (_1687)\n        {\n            _1688 = _1683;\n        }\n        else\n        {\n            _1688 = length(_1676);\n        }\n        float _1700 = _1688 - _745.fa_fog_b.x;\n        if (_1700 > 0.0)\n        {\n            float _1709 = _745.fa_fog.w * _1700;\n            float tau = _1709 * _1709;\n            if (_745.fa_fog_b.y > 0.0)\n            {\n                float _1725;\n                if (_1687)\n                {\n                    _1725 = in.fa_world_pos.y - (_745.fa_fog_c.y * _1683);\n                }\n                else\n                {\n                    _1725 = _745.fa_camera_pos.y;\n                }\n                float _1746 = mix(_1725, in.fa_world_pos.y, fast::clamp(_745.fa_fog_b.x / _1688, 0.0, 1.0));\n                float _1750 = in.fa_world_pos.y - _1746;\n                float _1755 = _1746 - _745.fa_fog_b.z;\n                float _1760 = in.fa_world_pos.y - _745.fa_fog_b.z;\n                bool _1763 = _1755 <= 0.0;\n                bool _1764 = !_1763;\n                bool _1770;\n                if (_1764)\n                {\n                    _1770 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1770 = _1763;\n                }\n                float _1771;\n                if (_1770)\n                {\n                    _1771 = _745.fa_fog_b.y;\n                }\n                else\n                {\n                    _1771 = _745.fa_fog_b.y * exp(-fast::min(_745.fa_fog_b.w * _1755, 80.0));\n                }\n                bool _1798;\n                if (_1764)\n                {\n                    _1798 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1798 = _1763;\n                }\n                float _1799;\n                if (_1798)\n                {\n                    _1799 = _745.fa_fog_b.y * _1755;\n                }\n                else\n                {\n                    _1799 = (_745.fa_fog_b.y * (1.0 - exp(-fast::min(_745.fa_fog_b.w * _1755, 80.0)))) / _745.fa_fog_b.w;\n                }\n                bool _1824 = _1760 <= 0.0;\n                bool _1831;\n                if (!_1824)\n                {\n                    _1831 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1831 = _1824;\n                }\n                float _1832;\n                if (_1831)\n                {\n                    _1832 = _745.fa_fog_b.y * _1760;\n                }\n                else\n                {\n                    _1832 = (_745.fa_fog_b.y * (1.0 - exp(-fast::min(_745.fa_fog_b.w * _1760, 80.0)))) / _745.fa_fog_b.w;\n                }\n                float _1859;\n                if (abs(_1750) < 0.001000000047497451305389404296875)\n                {\n                    _1859 = _1771;\n                }\n                else\n                {\n                    _1859 = (_1832 - _1799) / _1750;\n                }\n                tau += (_1700 * fast::max(_1859, 0.0));\n            }\n            result = mix(result, _745.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1941);\n    return out;\n}\n\n",
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
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_221",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_386",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_745",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1331 = fa_linear_to_srgb(param);\n        c = _1331;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1339 = fa_srgb_to_linear(param_1);\n            c = _1339;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _149;\n    if (bool(i.front_facing))\n    {\n        _149 = i.world_normal;\n    }\n    else\n    {\n        _149 = -i.world_normal;\n    }\n    float3 _173 = fast::normalize(i.world_tangent.xyz - (_149 * dot(_149, i.world_tangent.xyz)));\n    float3 _201 = fast::normalize(((_173 * m.x) + ((cross(_149, _173) * i.world_tangent.w) * m.y)) + (_149 * m.z));\n    float3 _204;\n    if (bool(i.front_facing))\n    {\n        _204 = _201;\n    }\n    else\n    {\n        _204 = -_201;\n    }\n    return _204;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _745, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _745.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1370 = fa_tex_fix(param_2, param_3);\n    float4 _2070 = base_t;\n    _2070.x = _1370.x;\n    _2070.y = _1370.y;\n    _2070.z = _1370.z;\n    base_t = _2070;\n    float4 _1384 = (_2070 * _745.fa_base_color) * i.vertex_color;\n    float3 _2038 = i.world_normal;\n    if (_745.fa_maps.z > 0.5)\n    {\n        float param_4 = _745.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1416 = fa_tex_fix(param_6, param_7);\n        float3 _1420 = (_1416 * 2.0) - float3(1.0);\n        float2 _1425 = _1420.xy * _745.fa_maps.x;\n        float3 _2078 = _1420;\n        _2078.x = _1425.x;\n        _2078.y = _1425.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2078;\n        _2038 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _745.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1454 = fa_tex_fix(param_12, param_13);\n    float4 _2081 = mrt;\n    _2081.x = _1454.x;\n    _2081.y = _1454.y;\n    _2081.z = _1454.z;\n    mrt = _2081;\n    float param_14 = _745.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1493 = fa_tex_fix(param_16, param_17);\n    float param_18 = _745.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1520 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1384.xyz, _1384.w, _2038, fast::clamp(_745.fa_pbr.x * _1454.z, 0.0, 1.0), fast::clamp(_745.fa_pbr.y * _1454.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_745.fa_maps.y * (_1493.x - 1.0)), _745.fa_emissive.xyz + (_745.fa_model_emissive.xyz * _1520) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _745, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_745.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _745.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1147 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1150 = _1147.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1150 * _1150, exp2((-9.27999973297119140625) * ndv)) * _1150) + _1147.y)) + _1147.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_745.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _745.fa_env_horizon.w)).xyz;\n    }\n    float _1052 = rough * rough;\n    float _1082 = 0.60000002384185791015625 * _1052;\n    return mix(mix(_745.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_745.fa_env_horizon.xyz, _745.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1052)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1082, 0.0500000007450580596923828125 + _1082, d.y))), ((_745.fa_env_sky.xyz + _745.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1052 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1189 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _745, fa_env_tex, fa_env_smp) * ((f0 * _1189.x) + float3(_1189.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _745, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _745, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _745, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _221)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _232 = _221.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_232)\n    {\n        l = fast::normalize(_221.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _250 = _221.fa_light_pos[li].xyz - world_pos;\n        float _252 = length(_250);\n        dist = _252;\n        l = _250 / float3(fast::max(_252, 9.9999997473787516355514526367188e-05));\n        float _268 = _252 / fast::max(_221.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _274 = fast::clamp(1.0 - (_268 * _268), 0.0, 1.0);\n        atten = _274 * _274;\n        if (_221.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_221.fa_light_dir[li].w, mix(_221.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_221.fa_light_dir[li].xyz)));\n        }\n    }\n    int _324;\n    if (_232)\n    {\n        _324 = 0;\n    }\n    else\n    {\n        _324 = (_221.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _221.fa_light_color[li].xyz * atten, atten, 1.0, dist, _324 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _386)\n{\n    float _376;\n    if (i == 0)\n    {\n        _376 = _386.fa_shadow_split.x;\n    }\n    else\n    {\n        float _392;\n        if (i == 1)\n        {\n            _392 = _386.fa_shadow_split.y;\n        }\n        else\n        {\n            float _400;\n            if (i == 2)\n            {\n                _400 = _386.fa_shadow_split.z;\n            }\n            else\n            {\n                _400 = _386.fa_shadow_split.w;\n            }\n            _392 = _400;\n        }\n        _376 = _392;\n    }\n    return _376;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _364 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_364), sin(_364)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _444 = fast::max(_386.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _449 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _455 = sqrt(1.0 - (_449 * _449));\n    float _463 = fast::min(_455 / fast::max(_449, 0.20000000298023223876953125), 4.0);\n    float _468;\n    if (_386.fa_shadow_bias.y > 0.0)\n    {\n        _468 = _386.fa_shadow_bias.y;\n    }\n    else\n    {\n        _468 = 1.5 * _386.fa_shadow_info[ci].x;\n    }\n    float4 _493 = _386.fa_shadow_mat[ci] * float4(world + (n * (_468 * _455)), 1.0);\n    float _500 = _493.x;\n    bool _503 = _500 < _386.fa_shadow_rect[ci].x;\n    bool _512;\n    if (!_503)\n    {\n        _512 = _500 > _386.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _512 = _503;\n    }\n    bool _521;\n    if (!_512)\n    {\n        _521 = _493.y < _386.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _521 = _512;\n    }\n    bool _530;\n    if (!_521)\n    {\n        _530 = _493.y > _386.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _530 = _521;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _493.z > 1.0;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return -1.0;\n    }\n    float _546;\n    if (_386.fa_shadow_bias.x > 0.0)\n    {\n        _546 = _386.fa_shadow_bias.x;\n    }\n    else\n    {\n        _546 = 1.5 * _386.fa_shadow_info[ci].x;\n    }\n    float _565 = _493.z - ((_546 * (1.0 + (0.5 * _463))) / _444);\n    float _574 = ((_386.fa_shadow_info[ci].x * fast::min(_463, 3.0)) * 0.5) / _444;\n    int _583 = int(_386.fa_shadow_cfg.z + 0.5);\n    if (_583 == 1)\n    {\n        float2 param = _493.xy;\n        float4 param_1 = _386.fa_shadow_rect[ci];\n        float _594 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_565 <= _594);\n    }\n    float _601 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _604 = _583 == 2;\n    if (_604)\n    {\n        float _618 = fast::clamp(((_386.fa_shadow_cfg.w * _444) * 0.25) / _386.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _601;\n            float2 _638 = fa_shadow_vogel(param_2, param_3, param_4) * _618;\n            float2 param_5 = _493.xy + (_638 * _386.fa_shadow_bias.zw);\n            float4 param_6 = _386.fa_shadow_rect[ci];\n            float _649 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_649 < (_565 - (length(_638) * _574)))\n            {\n                sum += _649;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_565 - (sum / cnt), 0.0) * _444) * _386.fa_shadow_cfg.w) / _386.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _693 = _604 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _693; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _693;\n        float param_9 = _601;\n        float2 _712 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _493.xy + (_712 * _386.fa_shadow_bias.zw);\n        float4 param_11 = _386.fa_shadow_rect[ci];\n        float _723 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_565 - (length(_712) * _574)) <= _723);\n    }\n    return lit / float(_693);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745)\n{\n    if (_745.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _756 = int(_386.fa_shadow_cfg.x + 0.5);\n    if (_756 < 1)\n    {\n        return 1.0;\n    }\n    float _772 = dot(world - _386.fa_shadow_eye.xyz, _386.fa_shadow_fwd.xyz);\n    int param = _756 - 1;\n    if (_772 > fa_shadow_split_at(param, _386))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _784 = _756 > 1;\n    bool _791;\n    if (_784)\n    {\n        _791 = _772 > _386.fa_shadow_split.x;\n    }\n    else\n    {\n        _791 = _784;\n    }\n    if (_791)\n    {\n        ci = 1;\n    }\n    bool _795 = _756 > 2;\n    bool _802;\n    if (_795)\n    {\n        _802 = _772 > _386.fa_shadow_split.y;\n    }\n    else\n    {\n        _802 = _795;\n    }\n    if (_802)\n    {\n        ci = 2;\n    }\n    bool _806 = _756 > 3;\n    bool _813;\n    if (_806)\n    {\n        _813 = _772 > _386.fa_shadow_split.z;\n    }\n    else\n    {\n        _813 = _806;\n    }\n    if (_813)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _756)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _839 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp);\n        s = _839;\n        if (_839 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_386.fa_shadow_cfg.y > 0.0)\n    {\n        float _864;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _864 = fa_shadow_split_at(param_5, _386);\n        }\n        else\n        {\n            _864 = _386.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _883 = _386.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _386) - _864, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _894 = fast::clamp((_772 - (fa_shadow_split_at(param_7, _386) - _883)) / _883, 0.0, 1.0);\n        if (_894 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _756)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _915 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp);\n                s2 = _915;\n                if (_915 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _894);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _221, thread float4& gl_FragCoord, constant fa_shadows& _386, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _745, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1244 = fa_light_sample(param, param_1, _221);\n    float3 _2023 = _1244.direction;\n    float3 _2018 = _1244.color;\n    float _2025 = _1244.attenuation;\n    float _2020 = _1244.shadow;\n    int _2028 = _1244.type;\n    if ((_2028 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2023;\n        float _1258 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745, fa_world_pos);\n        _2020 = _1258;\n        _2018 = _221.fa_light_color[li].xyz * (_2025 * _1258);\n    }\n    return LightSample{ _2023, _2018, _2025, _2020, _1244._distance, _2028 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _386)\n{\n    if (_386.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _939 = int(_386.fa_shadow_cfg.x + 0.5);\n    float _949 = dot(world - _386.fa_shadow_eye.xyz, _386.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _954 = _939 > 0;\n    bool _963;\n    if (_954)\n    {\n        int param = _939 - 1;\n        _963 = _949 <= fa_shadow_split_at(param, _386);\n    }\n    else\n    {\n        _963 = _954;\n    }\n    if (_963)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _970 = _939 > 1;\n        bool _977;\n        if (_970)\n        {\n            _977 = _949 > _386.fa_shadow_split.x;\n        }\n        else\n        {\n            _977 = _970;\n        }\n        if (_977)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _983 = _939 > 2;\n        bool _990;\n        if (_983)\n        {\n            _990 = _949 > _386.fa_shadow_split.y;\n        }\n        else\n        {\n            _990 = _983;\n        }\n        if (_990)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _996 = _939 > 3;\n        bool _1003;\n        if (_996)\n        {\n            _1003 = _949 > _386.fa_shadow_split.z;\n        }\n        else\n        {\n            _1003 = _996;\n        }\n        if (_1003)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _745 [[buffer(1)]], constant fa_lights& _221 [[buffer(2)]], constant fa_shadows& _386 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1901 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1901 = -_1901;\n    }\n    float3 _1563 = fast::normalize(_745.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n    Surface _1568 = fa_standard_surface(param, _745, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1940 = _1568.albedo;\n    float _1941 = _1568.alpha;\n    float3 _1942 = _1568.normal;\n    float _1943 = _1568.metallic;\n    float _1944 = _1568.roughness;\n    float _1945 = _1568.occlusion;\n    float3 _1946 = _1568.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n    Surface param_2 = _1568;\n    surface(param_1, param_2);\n    _1940 = param_2.albedo;\n    _1941 = param_2.alpha;\n    _1942 = param_2.normal;\n    _1943 = param_2.metallic;\n    _1944 = param_2.roughness;\n    _1945 = param_2.occlusion;\n    _1946 = param_2.emission;\n    float3 result;\n    if (_745.fa_emissive.w > 0.5)\n    {\n        result = _1940;\n    }\n    else\n    {\n        float3 _1589 = _1942;\n        float3 _1590 = fast::normalize(_1589);\n        _1942 = _1590;\n        float3 param_3 = _1590;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _1940, _1941, _1942, _1943, _1944, _1945, _1946 };\n        float3 param_6 = fa_ambient_light(param_3, _745, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_4, param_5, param_6, _745, fa_env_tex, fa_env_smp);\n        int _1610 = int(_745.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1610)\n            {\n                break;\n            }\n            int param_7 = li;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _1901;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _1901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1563, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _1940, _1941, _1942, _1943, _1944, _1945, _1946 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, _221, gl_FragCoord, _386, fa_shadow_tex, fa_shadow_smp, _745, in.fa_world_pos);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    float3 _1649 = result;\n    float3 _1650 = _1649 + _1946;\n    result = _1650;\n    float3 param_13 = _1650;\n    float3 param_14 = in.fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14, _386);\n    bool _1659 = _745.fa_fog.w > 0.0;\n    bool _1667;\n    if (!_1659)\n    {\n        _1667 = _745.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1667 = _1659;\n    }\n    if (_1667)\n    {\n        float3 _1676 = in.fa_world_pos - _745.fa_camera_pos.xyz;\n        float _1683 = dot(_1676, _745.fa_fog_c.xyz);\n        bool _1687 = _745.fa_fog_c.w > 0.5;\n        float _1688;\n        if (_1687)\n        {\n            _1688 = _1683;\n        }\n        else\n        {\n            _1688 = length(_1676);\n        }\n        float _1700 = _1688 - _745.fa_fog_b.x;\n        if (_1700 > 0.0)\n        {\n            float _1709 = _745.fa_fog.w * _1700;\n            float tau = _1709 * _1709;\n            if (_745.fa_fog_b.y > 0.0)\n            {\n                float _1725;\n                if (_1687)\n                {\n                    _1725 = in.fa_world_pos.y - (_745.fa_fog_c.y * _1683);\n                }\n                else\n                {\n                    _1725 = _745.fa_camera_pos.y;\n                }\n                float _1746 = mix(_1725, in.fa_world_pos.y, fast::clamp(_745.fa_fog_b.x / _1688, 0.0, 1.0));\n                float _1750 = in.fa_world_pos.y - _1746;\n                float _1755 = _1746 - _745.fa_fog_b.z;\n                float _1760 = in.fa_world_pos.y - _745.fa_fog_b.z;\n                bool _1763 = _1755 <= 0.0;\n                bool _1764 = !_1763;\n                bool _1770;\n                if (_1764)\n                {\n                    _1770 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1770 = _1763;\n                }\n                float _1771;\n                if (_1770)\n                {\n                    _1771 = _745.fa_fog_b.y;\n                }\n                else\n                {\n                    _1771 = _745.fa_fog_b.y * exp(-fast::min(_745.fa_fog_b.w * _1755, 80.0));\n                }\n                bool _1798;\n                if (_1764)\n                {\n                    _1798 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1798 = _1763;\n                }\n                float _1799;\n                if (_1798)\n                {\n                    _1799 = _745.fa_fog_b.y * _1755;\n                }\n                else\n                {\n                    _1799 = (_745.fa_fog_b.y * (1.0 - exp(-fast::min(_745.fa_fog_b.w * _1755, 80.0)))) / _745.fa_fog_b.w;\n                }\n                bool _1824 = _1760 <= 0.0;\n                bool _1831;\n                if (!_1824)\n                {\n                    _1831 = _745.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1831 = _1824;\n                }\n                float _1832;\n                if (_1831)\n                {\n                    _1832 = _745.fa_fog_b.y * _1760;\n                }\n                else\n                {\n                    _1832 = (_745.fa_fog_b.y * (1.0 - exp(-fast::min(_745.fa_fog_b.w * _1760, 80.0)))) / _745.fa_fog_b.w;\n                }\n                float _1859;\n                if (abs(_1750) < 0.001000000047497451305389404296875)\n                {\n                    _1859 = _1771;\n                }\n                else\n                {\n                    _1859 = (_1832 - _1799) / _1750;\n                }\n                tau += (_1700 * fast::max(_1859, 0.0));\n            }\n            result = mix(result, _745.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1941);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_221",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_386",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_745",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _586 = base_t;\n    _586.x = _225.x;\n    _586.y = _225.y;\n    _586.z = _225.z;\n    base_t = _586;\n    float4 _241 = (_586 * _213.fa_base_color) * i.vertex_color;\n    float3 _567 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _594 = _279;\n        _594.x = _284.x;\n        _594.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _594;\n        _567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _597 = mrt;\n    _597.x = _313.x;\n    _597.y = _313.y;\n    _597.z = _313.z;\n    mrt = _597;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _567, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _514 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _514 = -_514;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _514, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _514, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _586 = base_t;\n    _586.x = _225.x;\n    _586.y = _225.y;\n    _586.z = _225.z;\n    base_t = _586;\n    float4 _241 = (_586 * _213.fa_base_color) * i.vertex_color;\n    float3 _567 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _594 = _279;\n        _594.x = _284.x;\n        _594.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _594;\n        _567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _597 = mrt;\n    _597.x = _313.x;\n    _597.y = _313.y;\n    _597.z = _313.z;\n    mrt = _597;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _567, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _514 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _514 = -_514;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _514, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _514, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
