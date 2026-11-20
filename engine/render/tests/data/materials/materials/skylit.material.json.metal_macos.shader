{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390)\n{\n    bool _395 = _390.fa_cl_info.x < 0.0;\n    bool _402;\n    if (!_395)\n    {\n        _402 = _390.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _402 = _395;\n    }\n    bool _410;\n    if (!_402)\n    {\n        _410 = _390.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _410 = _402;\n    }\n    bool _417;\n    if (!_410)\n    {\n        _417 = _390.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _417 = _410;\n    }\n    bool _424;\n    if (!_417)\n    {\n        _424 = _390.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _424 = _417;\n    }\n    if (_424)\n    {\n        return int2(0);\n    }\n    float4 _434 = float4(world_pos, 1.0);\n    float _441 = dot(_390.fa_cl_vpw, _434);\n    if (!(_441 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _463 = float2(dot(_390.fa_cl_vpx, _434), dot(_390.fa_cl_vpy, _434)) / float2(_441);\n    int _467 = int(_390.fa_cl_grid.x);\n    int _471 = int(_390.fa_cl_grid.y);\n    int param = (int(_390.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_390.fa_cl_fwd.xyz, world_pos) + _390.fa_cl_fwd.w, _390.fa_cl_grid.w) / _390.fa_cl_grid.w) * _390.fa_cl_grid.z)), 0, int(_390.fa_cl_info.y) - 1) * _471) + clamp(int(floor(((_463.y * 0.5) + 0.5) * _390.fa_cl_grid.y)), 0, _471 - 1)) * _467)) + clamp(int(floor(((_463.x * 0.5) + 0.5) * _390.fa_cl_grid.x)), 0, _467 - 1);\n    float4 _542 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_542.x), int(_542.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_390.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1478 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _390);\n    fa_cl_slot = _1478.x;\n    fa_cl_local = _1478.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1588 = fa_linear_to_srgb(param);\n        c = _1588;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1596 = fa_srgb_to_linear(param_1);\n            c = _1596;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _171;\n    if (bool(i.front_facing))\n    {\n        _171 = i.world_normal;\n    }\n    else\n    {\n        _171 = -i.world_normal;\n    }\n    float3 _195 = fast::normalize(i.world_tangent.xyz - (_171 * dot(_171, i.world_tangent.xyz)));\n    float3 _223 = fast::normalize(((_195 * m.x) + ((cross(_171, _195) * i.world_tangent.w) * m.y)) + (_171 * m.z));\n    float3 _226;\n    if (bool(i.front_facing))\n    {\n        _226 = _223;\n    }\n    else\n    {\n        _226 = -_223;\n    }\n    return _226;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _390, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _390.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1627 = fa_tex_fix(param_2, param_3);\n    float4 _2336 = base_t;\n    _2336.x = _1627.x;\n    _2336.y = _1627.y;\n    _2336.z = _1627.z;\n    base_t = _2336;\n    float4 _1641 = (_2336 * _390.fa_base_color) * i.vertex_color;\n    float3 _2295 = i.world_normal;\n    if (_390.fa_maps.z > 0.5)\n    {\n        float param_4 = _390.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1673 = fa_tex_fix(param_6, param_7);\n        float3 _1677 = (_1673 * 2.0) - float3(1.0);\n        float2 _1682 = _1677.xy * _390.fa_maps.x;\n        float3 _2344 = _1677;\n        _2344.x = _1682.x;\n        _2344.y = _1682.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2344;\n        _2295 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _390.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1711 = fa_tex_fix(param_12, param_13);\n    float4 _2347 = mrt;\n    _2347.x = _1711.x;\n    _2347.y = _1711.y;\n    _2347.z = _1711.z;\n    mrt = _2347;\n    float param_14 = _390.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1750 = fa_tex_fix(param_16, param_17);\n    float param_18 = _390.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1777 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1641.xyz, _1641.w, _2295, fast::clamp(_390.fa_pbr.x * _1711.z, 0.0, 1.0), fast::clamp(_390.fa_pbr.y * _1711.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_390.fa_maps.y * (_1750.x - 1.0)), _390.fa_emissive.xyz + (_390.fa_model_emissive.xyz * _1777) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _390.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1377 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1380 = _1377.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1380 * _1380, exp2((-9.27999973297119140625) * ndv)) * _1380) + _1377.y)) + _1377.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _390.fa_env_horizon.w)).xyz;\n    }\n    float _1282 = rough * rough;\n    float _1312 = 0.60000002384185791015625 * _1282;\n    return mix(mix(_390.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_390.fa_env_horizon.xyz, _390.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1282)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1312, 0.0500000007450580596923828125 + _1312, d.y))), ((_390.fa_env_sky.xyz + _390.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1282 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _390, fa_env_tex, fa_env_smp) * ((f0 * _1419.x) + float3(_1419.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _390, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _390, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390)\n{\n    int param = (int(_390.fa_cl_info.x) + int(_390.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _390);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _263 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _269 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _272 = _269.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _279 = _272 < 0.5;\n    float3 l;\n    if (_279)\n    {\n        l = fast::normalize(_263.xyz);\n    }\n    else\n    {\n        float3 _291 = _263.xyz - world_pos;\n        float _293 = length(_291);\n        dist = _293;\n        l = _291 / float3(fast::max(_293, 9.9999997473787516355514526367188e-05));\n        float _308 = _293 / fast::max(_263.w, 0.001000000047497451305389404296875);\n        float _314 = fast::clamp(1.0 - (_308 * _308), 0.0, 1.0);\n        atten = _314 * _314;\n        if (_272 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _328 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _338 = _328.w;\n            int param_3 = (li * 4) + 3;\n            float4 _345 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _346 = _345.x;\n            float cos_inner = _346;\n            if (_346 > 1.5)\n            {\n                cos_inner = mix(_338, 1.0, 0.25);\n            }\n            atten *= smoothstep(_338, cos_inner, dot(-l, fast::normalize(_328.xyz)));\n        }\n    }\n    int _376;\n    if (_279)\n    {\n        _376 = 0;\n    }\n    else\n    {\n        _376 = (_272 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _269.xyz * atten, atten, 1.0, dist, _376 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _626)\n{\n    float _616;\n    if (i == 0)\n    {\n        _616 = _626.fa_shadow_split.x;\n    }\n    else\n    {\n        float _632;\n        if (i == 1)\n        {\n            _632 = _626.fa_shadow_split.y;\n        }\n        else\n        {\n            float _640;\n            if (i == 2)\n            {\n                _640 = _626.fa_shadow_split.z;\n            }\n            else\n            {\n                _640 = _626.fa_shadow_split.w;\n            }\n            _632 = _640;\n        }\n        _616 = _632;\n    }\n    return _616;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _604 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_604), sin(_604)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex)\n{\n    float _678 = fast::max(_626.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _683 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _689 = sqrt(1.0 - (_683 * _683));\n    float _697 = fast::min(_689 / fast::max(_683, 0.20000000298023223876953125), 4.0);\n    float _702;\n    if (_626.fa_shadow_bias.y > 0.0)\n    {\n        _702 = _626.fa_shadow_bias.y;\n    }\n    else\n    {\n        _702 = 1.5 * _626.fa_shadow_info[ci].x;\n    }\n    float4 _727 = _626.fa_shadow_mat[ci] * float4(world + (n * (_702 * _689)), 1.0);\n    float _734 = _727.x;\n    bool _737 = _734 < _626.fa_shadow_rect[ci].x;\n    bool _746;\n    if (!_737)\n    {\n        _746 = _734 > _626.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _746 = _737;\n    }\n    bool _755;\n    if (!_746)\n    {\n        _755 = _727.y < _626.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _755 = _746;\n    }\n    bool _764;\n    if (!_755)\n    {\n        _764 = _727.y > _626.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _764 = _755;\n    }\n    bool _771;\n    if (!_764)\n    {\n        _771 = _727.z > 1.0;\n    }\n    else\n    {\n        _771 = _764;\n    }\n    if (_771)\n    {\n        return -1.0;\n    }\n    float _780;\n    if (_626.fa_shadow_bias.x > 0.0)\n    {\n        _780 = _626.fa_shadow_bias.x;\n    }\n    else\n    {\n        _780 = 1.5 * _626.fa_shadow_info[ci].x;\n    }\n    float _799 = _727.z - ((_780 * (1.0 + (0.5 * _697))) / _678);\n    float _808 = ((_626.fa_shadow_info[ci].x * fast::min(_697, 3.0)) * 0.5) / _678;\n    int _817 = int(_626.fa_shadow_cfg.z + 0.5);\n    if (_817 == 1)\n    {\n        float2 param = _727.xy;\n        float4 param_1 = _626.fa_shadow_rect[ci];\n        float _828 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_799 <= _828);\n    }\n    float _835 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _838 = _817 == 2;\n    if (_838)\n    {\n        float _852 = fast::clamp(((_626.fa_shadow_cfg.w * _678) * 0.25) / _626.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _835;\n            float2 _871 = fa_shadow_vogel(param_2, param_3, param_4) * _852;\n            float2 param_5 = _727.xy + (_871 * _626.fa_shadow_bias.zw);\n            float4 param_6 = _626.fa_shadow_rect[ci];\n            float _882 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_882 < (_799 - (length(_871) * _808)))\n            {\n                sum += _882;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_799 - (sum / cnt), 0.0) * _678) * _626.fa_shadow_cfg.w) / _626.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _926 = _838 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _926; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _926;\n        float param_9 = _835;\n        float2 _945 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _727.xy + (_945 * _626.fa_shadow_bias.zw);\n        float4 param_11 = _626.fa_shadow_rect[ci];\n        float _956 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_799 - (length(_945) * _808)) <= _956);\n    }\n    return lit / float(_926);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex)\n{\n    if (_390.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _986 = int(_626.fa_shadow_cfg.x + 0.5);\n    if (_986 < 1)\n    {\n        return 1.0;\n    }\n    float _1002 = dot(world - _626.fa_shadow_eye.xyz, _626.fa_shadow_fwd.xyz);\n    int param = _986 - 1;\n    if (_1002 > fa_shadow_split_at(param, _626))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1014 = _986 > 1;\n    bool _1021;\n    if (_1014)\n    {\n        _1021 = _1002 > _626.fa_shadow_split.x;\n    }\n    else\n    {\n        _1021 = _1014;\n    }\n    if (_1021)\n    {\n        ci = 1;\n    }\n    bool _1025 = _986 > 2;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1002 > _626.fa_shadow_split.y;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 2;\n    }\n    bool _1036 = _986 > 3;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1002 > _626.fa_shadow_split.z;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _986)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1069 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _626, fa_shadow_tex);\n        s = _1069;\n        if (_1069 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_626.fa_shadow_cfg.y > 0.0)\n    {\n        float _1094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1094 = fa_shadow_split_at(param_5, _626);\n        }\n        else\n        {\n            _1094 = _626.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1113 = _626.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _626) - _1094, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1124 = fast::clamp((_1002 - (fa_shadow_split_at(param_7, _626) - _1113)) / _1113, 0.0, 1.0);\n        if (_1124 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _986)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1145 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _626, fa_shadow_tex);\n                s2 = _1145;\n                if (_1145 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1124);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1506 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2280 = _1506.direction;\n    float3 _2275 = _1506.color;\n    float _2277 = _1506.shadow;\n    int _2285 = _1506.type;\n    if ((_2285 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2280;\n        float _1520 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex, fa_world_pos);\n        _2277 = _1520;\n        _2275 *= _1520;\n    }\n    return LightSample{ _2280, _2275, _1506.attenuation, _2277, _1506._distance, _2285 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _626)\n{\n    if (_626.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1169 = int(_626.fa_shadow_cfg.x + 0.5);\n    float _1179 = dot(world - _626.fa_shadow_eye.xyz, _626.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1184 = _1169 > 0;\n    bool _1193;\n    if (_1184)\n    {\n        int param = _1169 - 1;\n        _1193 = _1179 <= fa_shadow_split_at(param, _626);\n    }\n    else\n    {\n        _1193 = _1184;\n    }\n    if (_1193)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1200 = _1169 > 1;\n        bool _1207;\n        if (_1200)\n        {\n            _1207 = _1179 > _626.fa_shadow_split.x;\n        }\n        else\n        {\n            _1207 = _1200;\n        }\n        if (_1207)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1213 = _1169 > 2;\n        bool _1220;\n        if (_1213)\n        {\n            _1220 = _1179 > _626.fa_shadow_split.y;\n        }\n        else\n        {\n            _1220 = _1213;\n        }\n        if (_1220)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1226 = _1169 > 3;\n        bool _1233;\n        if (_1226)\n        {\n            _1233 = _1179 > _626.fa_shadow_split.z;\n        }\n        else\n        {\n            _1233 = _1226;\n        }\n        if (_1233)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _390 [[buffer(1)]], constant fa_shadows& _626 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2158 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2158 = -_2158;\n    }\n    float3 _1820 = fast::normalize(_390.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _390, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n    Surface _1828 = fa_standard_surface(param_1, _390, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2197 = _1828.albedo;\n    float _2198 = _1828.alpha;\n    float3 _2199 = _1828.normal;\n    float _2200 = _1828.metallic;\n    float _2201 = _1828.roughness;\n    float _2202 = _1828.occlusion;\n    float3 _2203 = _1828.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n    Surface param_3 = _1828;\n    surface(param_2, param_3);\n    _2197 = param_3.albedo;\n    _2198 = param_3.alpha;\n    _2199 = param_3.normal;\n    _2200 = param_3.metallic;\n    _2201 = param_3.roughness;\n    _2202 = param_3.occlusion;\n    _2203 = param_3.emission;\n    float3 result;\n    if (_390.fa_emissive.w > 0.5)\n    {\n        result = _2197;\n    }\n    else\n    {\n        float3 _1849 = _2199;\n        float3 _1850 = fast::normalize(_1849);\n        _2199 = _1850;\n        float3 param_4 = _1850;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2197, _2198, _2199, _2200, _2201, _2202, _2203 };\n        float3 param_7 = fa_ambient_light(param_4, _390, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7, _390, fa_env_tex, fa_env_smp);\n        int _1869 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1869; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _390, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2158;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2197, _2198, _2199, _2200, _2201, _2202, _2203 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _1906 = result;\n    float3 _1907 = _1906 + _2203;\n    result = _1907;\n    float3 param_15 = _1907;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _626);\n    bool _1916 = _390.fa_fog.w > 0.0;\n    bool _1924;\n    if (!_1916)\n    {\n        _1924 = _390.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1924 = _1916;\n    }\n    if (_1924)\n    {\n        float3 _1933 = in.fa_world_pos - _390.fa_camera_pos.xyz;\n        float _1940 = dot(_1933, _390.fa_fog_c.xyz);\n        bool _1944 = _390.fa_fog_c.w > 0.5;\n        float _1945;\n        if (_1944)\n        {\n            _1945 = _1940;\n        }\n        else\n        {\n            _1945 = length(_1933);\n        }\n        float _1957 = _1945 - _390.fa_fog_b.x;\n        if (_1957 > 0.0)\n        {\n            float _1966 = _390.fa_fog.w * _1957;\n            float tau = _1966 * _1966;\n            if (_390.fa_fog_b.y > 0.0)\n            {\n                float _1982;\n                if (_1944)\n                {\n                    _1982 = in.fa_world_pos.y - (_390.fa_fog_c.y * _1940);\n                }\n                else\n                {\n                    _1982 = _390.fa_camera_pos.y;\n                }\n                float _2003 = mix(_1982, in.fa_world_pos.y, fast::clamp(_390.fa_fog_b.x / _1945, 0.0, 1.0));\n                float _2007 = in.fa_world_pos.y - _2003;\n                float _2012 = _2003 - _390.fa_fog_b.z;\n                float _2017 = in.fa_world_pos.y - _390.fa_fog_b.z;\n                bool _2020 = _2012 <= 0.0;\n                bool _2021 = !_2020;\n                bool _2027;\n                if (_2021)\n                {\n                    _2027 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2027 = _2020;\n                }\n                float _2028;\n                if (_2027)\n                {\n                    _2028 = _390.fa_fog_b.y;\n                }\n                else\n                {\n                    _2028 = _390.fa_fog_b.y * exp(-fast::min(_390.fa_fog_b.w * _2012, 80.0));\n                }\n                bool _2055;\n                if (_2021)\n                {\n                    _2055 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2055 = _2020;\n                }\n                float _2056;\n                if (_2055)\n                {\n                    _2056 = _390.fa_fog_b.y * _2012;\n                }\n                else\n                {\n                    _2056 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _2012, 80.0)))) / _390.fa_fog_b.w;\n                }\n                bool _2081 = _2017 <= 0.0;\n                bool _2088;\n                if (!_2081)\n                {\n                    _2088 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2088 = _2081;\n                }\n                float _2089;\n                if (_2088)\n                {\n                    _2089 = _390.fa_fog_b.y * _2017;\n                }\n                else\n                {\n                    _2089 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _2017, 80.0)))) / _390.fa_fog_b.w;\n                }\n                float _2116;\n                if (abs(_2007) < 0.001000000047497451305389404296875)\n                {\n                    _2116 = _2028;\n                }\n                else\n                {\n                    _2116 = (_2089 - _2056) / _2007;\n                }\n                tau += (_1957 * fast::max(_2116, 0.0));\n            }\n            result = mix(result, _390.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2198);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_626",
            "msl_buffer_n": 7
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 8
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390)\n{\n    bool _395 = _390.fa_cl_info.x < 0.0;\n    bool _402;\n    if (!_395)\n    {\n        _402 = _390.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _402 = _395;\n    }\n    bool _410;\n    if (!_402)\n    {\n        _410 = _390.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _410 = _402;\n    }\n    bool _417;\n    if (!_410)\n    {\n        _417 = _390.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _417 = _410;\n    }\n    bool _424;\n    if (!_417)\n    {\n        _424 = _390.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _424 = _417;\n    }\n    if (_424)\n    {\n        return int2(0);\n    }\n    float4 _434 = float4(world_pos, 1.0);\n    float _441 = dot(_390.fa_cl_vpw, _434);\n    if (!(_441 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _463 = float2(dot(_390.fa_cl_vpx, _434), dot(_390.fa_cl_vpy, _434)) / float2(_441);\n    int _467 = int(_390.fa_cl_grid.x);\n    int _471 = int(_390.fa_cl_grid.y);\n    int param = (int(_390.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_390.fa_cl_fwd.xyz, world_pos) + _390.fa_cl_fwd.w, _390.fa_cl_grid.w) / _390.fa_cl_grid.w) * _390.fa_cl_grid.z)), 0, int(_390.fa_cl_info.y) - 1) * _471) + clamp(int(floor(((_463.y * 0.5) + 0.5) * _390.fa_cl_grid.y)), 0, _471 - 1)) * _467)) + clamp(int(floor(((_463.x * 0.5) + 0.5) * _390.fa_cl_grid.x)), 0, _467 - 1);\n    float4 _542 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_542.x), int(_542.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_390.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1478 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _390);\n    fa_cl_slot = _1478.x;\n    fa_cl_local = _1478.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1588 = fa_linear_to_srgb(param);\n        c = _1588;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1596 = fa_srgb_to_linear(param_1);\n            c = _1596;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _171;\n    if (bool(i.front_facing))\n    {\n        _171 = i.world_normal;\n    }\n    else\n    {\n        _171 = -i.world_normal;\n    }\n    float3 _195 = fast::normalize(i.world_tangent.xyz - (_171 * dot(_171, i.world_tangent.xyz)));\n    float3 _223 = fast::normalize(((_195 * m.x) + ((cross(_171, _195) * i.world_tangent.w) * m.y)) + (_171 * m.z));\n    float3 _226;\n    if (bool(i.front_facing))\n    {\n        _226 = _223;\n    }\n    else\n    {\n        _226 = -_223;\n    }\n    return _226;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _390, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _390.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1627 = fa_tex_fix(param_2, param_3);\n    float4 _2336 = base_t;\n    _2336.x = _1627.x;\n    _2336.y = _1627.y;\n    _2336.z = _1627.z;\n    base_t = _2336;\n    float4 _1641 = (_2336 * _390.fa_base_color) * i.vertex_color;\n    float3 _2295 = i.world_normal;\n    if (_390.fa_maps.z > 0.5)\n    {\n        float param_4 = _390.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1673 = fa_tex_fix(param_6, param_7);\n        float3 _1677 = (_1673 * 2.0) - float3(1.0);\n        float2 _1682 = _1677.xy * _390.fa_maps.x;\n        float3 _2344 = _1677;\n        _2344.x = _1682.x;\n        _2344.y = _1682.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2344;\n        _2295 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _390.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1711 = fa_tex_fix(param_12, param_13);\n    float4 _2347 = mrt;\n    _2347.x = _1711.x;\n    _2347.y = _1711.y;\n    _2347.z = _1711.z;\n    mrt = _2347;\n    float param_14 = _390.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1750 = fa_tex_fix(param_16, param_17);\n    float param_18 = _390.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1777 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1641.xyz, _1641.w, _2295, fast::clamp(_390.fa_pbr.x * _1711.z, 0.0, 1.0), fast::clamp(_390.fa_pbr.y * _1711.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_390.fa_maps.y * (_1750.x - 1.0)), _390.fa_emissive.xyz + (_390.fa_model_emissive.xyz * _1777) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _390.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1377 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1380 = _1377.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1380 * _1380, exp2((-9.27999973297119140625) * ndv)) * _1380) + _1377.y)) + _1377.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _390.fa_env_horizon.w)).xyz;\n    }\n    float _1282 = rough * rough;\n    float _1312 = 0.60000002384185791015625 * _1282;\n    return mix(mix(_390.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_390.fa_env_horizon.xyz, _390.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1282)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1312, 0.0500000007450580596923828125 + _1312, d.y))), ((_390.fa_env_sky.xyz + _390.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1282 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _390, fa_env_tex, fa_env_smp) * ((f0 * _1419.x) + float3(_1419.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _390, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _390, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _390, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390)\n{\n    int param = (int(_390.fa_cl_info.x) + int(_390.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _390);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _263 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _269 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _272 = _269.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _279 = _272 < 0.5;\n    float3 l;\n    if (_279)\n    {\n        l = fast::normalize(_263.xyz);\n    }\n    else\n    {\n        float3 _291 = _263.xyz - world_pos;\n        float _293 = length(_291);\n        dist = _293;\n        l = _291 / float3(fast::max(_293, 9.9999997473787516355514526367188e-05));\n        float _308 = _293 / fast::max(_263.w, 0.001000000047497451305389404296875);\n        float _314 = fast::clamp(1.0 - (_308 * _308), 0.0, 1.0);\n        atten = _314 * _314;\n        if (_272 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _328 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _338 = _328.w;\n            int param_3 = (li * 4) + 3;\n            float4 _345 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _346 = _345.x;\n            float cos_inner = _346;\n            if (_346 > 1.5)\n            {\n                cos_inner = mix(_338, 1.0, 0.25);\n            }\n            atten *= smoothstep(_338, cos_inner, dot(-l, fast::normalize(_328.xyz)));\n        }\n    }\n    int _376;\n    if (_279)\n    {\n        _376 = 0;\n    }\n    else\n    {\n        _376 = (_272 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _269.xyz * atten, atten, 1.0, dist, _376 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _626)\n{\n    float _616;\n    if (i == 0)\n    {\n        _616 = _626.fa_shadow_split.x;\n    }\n    else\n    {\n        float _632;\n        if (i == 1)\n        {\n            _632 = _626.fa_shadow_split.y;\n        }\n        else\n        {\n            float _640;\n            if (i == 2)\n            {\n                _640 = _626.fa_shadow_split.z;\n            }\n            else\n            {\n                _640 = _626.fa_shadow_split.w;\n            }\n            _632 = _640;\n        }\n        _616 = _632;\n    }\n    return _616;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _604 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_604), sin(_604)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex)\n{\n    float _678 = fast::max(_626.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _683 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _689 = sqrt(1.0 - (_683 * _683));\n    float _697 = fast::min(_689 / fast::max(_683, 0.20000000298023223876953125), 4.0);\n    float _702;\n    if (_626.fa_shadow_bias.y > 0.0)\n    {\n        _702 = _626.fa_shadow_bias.y;\n    }\n    else\n    {\n        _702 = 1.5 * _626.fa_shadow_info[ci].x;\n    }\n    float4 _727 = _626.fa_shadow_mat[ci] * float4(world + (n * (_702 * _689)), 1.0);\n    float _734 = _727.x;\n    bool _737 = _734 < _626.fa_shadow_rect[ci].x;\n    bool _746;\n    if (!_737)\n    {\n        _746 = _734 > _626.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _746 = _737;\n    }\n    bool _755;\n    if (!_746)\n    {\n        _755 = _727.y < _626.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _755 = _746;\n    }\n    bool _764;\n    if (!_755)\n    {\n        _764 = _727.y > _626.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _764 = _755;\n    }\n    bool _771;\n    if (!_764)\n    {\n        _771 = _727.z > 1.0;\n    }\n    else\n    {\n        _771 = _764;\n    }\n    if (_771)\n    {\n        return -1.0;\n    }\n    float _780;\n    if (_626.fa_shadow_bias.x > 0.0)\n    {\n        _780 = _626.fa_shadow_bias.x;\n    }\n    else\n    {\n        _780 = 1.5 * _626.fa_shadow_info[ci].x;\n    }\n    float _799 = _727.z - ((_780 * (1.0 + (0.5 * _697))) / _678);\n    float _808 = ((_626.fa_shadow_info[ci].x * fast::min(_697, 3.0)) * 0.5) / _678;\n    int _817 = int(_626.fa_shadow_cfg.z + 0.5);\n    if (_817 == 1)\n    {\n        float2 param = _727.xy;\n        float4 param_1 = _626.fa_shadow_rect[ci];\n        float _828 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_799 <= _828);\n    }\n    float _835 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _838 = _817 == 2;\n    if (_838)\n    {\n        float _852 = fast::clamp(((_626.fa_shadow_cfg.w * _678) * 0.25) / _626.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _835;\n            float2 _871 = fa_shadow_vogel(param_2, param_3, param_4) * _852;\n            float2 param_5 = _727.xy + (_871 * _626.fa_shadow_bias.zw);\n            float4 param_6 = _626.fa_shadow_rect[ci];\n            float _882 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_882 < (_799 - (length(_871) * _808)))\n            {\n                sum += _882;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_799 - (sum / cnt), 0.0) * _678) * _626.fa_shadow_cfg.w) / _626.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _926 = _838 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _926; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _926;\n        float param_9 = _835;\n        float2 _945 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _727.xy + (_945 * _626.fa_shadow_bias.zw);\n        float4 param_11 = _626.fa_shadow_rect[ci];\n        float _956 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_799 - (length(_945) * _808)) <= _956);\n    }\n    return lit / float(_926);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex)\n{\n    if (_390.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _986 = int(_626.fa_shadow_cfg.x + 0.5);\n    if (_986 < 1)\n    {\n        return 1.0;\n    }\n    float _1002 = dot(world - _626.fa_shadow_eye.xyz, _626.fa_shadow_fwd.xyz);\n    int param = _986 - 1;\n    if (_1002 > fa_shadow_split_at(param, _626))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1014 = _986 > 1;\n    bool _1021;\n    if (_1014)\n    {\n        _1021 = _1002 > _626.fa_shadow_split.x;\n    }\n    else\n    {\n        _1021 = _1014;\n    }\n    if (_1021)\n    {\n        ci = 1;\n    }\n    bool _1025 = _986 > 2;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1002 > _626.fa_shadow_split.y;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 2;\n    }\n    bool _1036 = _986 > 3;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1002 > _626.fa_shadow_split.z;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _986)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1069 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _626, fa_shadow_tex);\n        s = _1069;\n        if (_1069 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_626.fa_shadow_cfg.y > 0.0)\n    {\n        float _1094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1094 = fa_shadow_split_at(param_5, _626);\n        }\n        else\n        {\n            _1094 = _626.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1113 = _626.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _626) - _1094, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1124 = fast::clamp((_1002 - (fa_shadow_split_at(param_7, _626) - _1113)) / _1113, 0.0, 1.0);\n        if (_1124 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _986)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1145 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _626, fa_shadow_tex);\n                s2 = _1145;\n                if (_1145 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1124);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _390, thread float4& gl_FragCoord, constant fa_shadows& _626, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1506 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2280 = _1506.direction;\n    float3 _2275 = _1506.color;\n    float _2277 = _1506.shadow;\n    int _2285 = _1506.type;\n    if ((_2285 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2280;\n        float _1520 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex, fa_world_pos);\n        _2277 = _1520;\n        _2275 *= _1520;\n    }\n    return LightSample{ _2280, _2275, _1506.attenuation, _2277, _1506._distance, _2285 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _626)\n{\n    if (_626.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1169 = int(_626.fa_shadow_cfg.x + 0.5);\n    float _1179 = dot(world - _626.fa_shadow_eye.xyz, _626.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1184 = _1169 > 0;\n    bool _1193;\n    if (_1184)\n    {\n        int param = _1169 - 1;\n        _1193 = _1179 <= fa_shadow_split_at(param, _626);\n    }\n    else\n    {\n        _1193 = _1184;\n    }\n    if (_1193)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1200 = _1169 > 1;\n        bool _1207;\n        if (_1200)\n        {\n            _1207 = _1179 > _626.fa_shadow_split.x;\n        }\n        else\n        {\n            _1207 = _1200;\n        }\n        if (_1207)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1213 = _1169 > 2;\n        bool _1220;\n        if (_1213)\n        {\n            _1220 = _1179 > _626.fa_shadow_split.y;\n        }\n        else\n        {\n            _1220 = _1213;\n        }\n        if (_1220)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1226 = _1169 > 3;\n        bool _1233;\n        if (_1226)\n        {\n            _1233 = _1179 > _626.fa_shadow_split.z;\n        }\n        else\n        {\n            _1233 = _1226;\n        }\n        if (_1233)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _390 [[buffer(1)]], constant fa_shadows& _626 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2158 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2158 = -_2158;\n    }\n    float3 _1820 = fast::normalize(_390.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _390, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n    Surface _1828 = fa_standard_surface(param_1, _390, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2197 = _1828.albedo;\n    float _2198 = _1828.alpha;\n    float3 _2199 = _1828.normal;\n    float _2200 = _1828.metallic;\n    float _2201 = _1828.roughness;\n    float _2202 = _1828.occlusion;\n    float3 _2203 = _1828.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n    Surface param_3 = _1828;\n    surface(param_2, param_3);\n    _2197 = param_3.albedo;\n    _2198 = param_3.alpha;\n    _2199 = param_3.normal;\n    _2200 = param_3.metallic;\n    _2201 = param_3.roughness;\n    _2202 = param_3.occlusion;\n    _2203 = param_3.emission;\n    float3 result;\n    if (_390.fa_emissive.w > 0.5)\n    {\n        result = _2197;\n    }\n    else\n    {\n        float3 _1849 = _2199;\n        float3 _1850 = fast::normalize(_1849);\n        _2199 = _1850;\n        float3 param_4 = _1850;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2197, _2198, _2199, _2200, _2201, _2202, _2203 };\n        float3 param_7 = fa_ambient_light(param_4, _390, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7, _390, fa_env_tex, fa_env_smp);\n        int _1869 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1869; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _390, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2158;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2158, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1820, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2197, _2198, _2199, _2200, _2201, _2202, _2203 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _390, gl_FragCoord, _626, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _1906 = result;\n    float3 _1907 = _1906 + _2203;\n    result = _1907;\n    float3 param_15 = _1907;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _626);\n    bool _1916 = _390.fa_fog.w > 0.0;\n    bool _1924;\n    if (!_1916)\n    {\n        _1924 = _390.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1924 = _1916;\n    }\n    if (_1924)\n    {\n        float3 _1933 = in.fa_world_pos - _390.fa_camera_pos.xyz;\n        float _1940 = dot(_1933, _390.fa_fog_c.xyz);\n        bool _1944 = _390.fa_fog_c.w > 0.5;\n        float _1945;\n        if (_1944)\n        {\n            _1945 = _1940;\n        }\n        else\n        {\n            _1945 = length(_1933);\n        }\n        float _1957 = _1945 - _390.fa_fog_b.x;\n        if (_1957 > 0.0)\n        {\n            float _1966 = _390.fa_fog.w * _1957;\n            float tau = _1966 * _1966;\n            if (_390.fa_fog_b.y > 0.0)\n            {\n                float _1982;\n                if (_1944)\n                {\n                    _1982 = in.fa_world_pos.y - (_390.fa_fog_c.y * _1940);\n                }\n                else\n                {\n                    _1982 = _390.fa_camera_pos.y;\n                }\n                float _2003 = mix(_1982, in.fa_world_pos.y, fast::clamp(_390.fa_fog_b.x / _1945, 0.0, 1.0));\n                float _2007 = in.fa_world_pos.y - _2003;\n                float _2012 = _2003 - _390.fa_fog_b.z;\n                float _2017 = in.fa_world_pos.y - _390.fa_fog_b.z;\n                bool _2020 = _2012 <= 0.0;\n                bool _2021 = !_2020;\n                bool _2027;\n                if (_2021)\n                {\n                    _2027 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2027 = _2020;\n                }\n                float _2028;\n                if (_2027)\n                {\n                    _2028 = _390.fa_fog_b.y;\n                }\n                else\n                {\n                    _2028 = _390.fa_fog_b.y * exp(-fast::min(_390.fa_fog_b.w * _2012, 80.0));\n                }\n                bool _2055;\n                if (_2021)\n                {\n                    _2055 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2055 = _2020;\n                }\n                float _2056;\n                if (_2055)\n                {\n                    _2056 = _390.fa_fog_b.y * _2012;\n                }\n                else\n                {\n                    _2056 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _2012, 80.0)))) / _390.fa_fog_b.w;\n                }\n                bool _2081 = _2017 <= 0.0;\n                bool _2088;\n                if (!_2081)\n                {\n                    _2088 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2088 = _2081;\n                }\n                float _2089;\n                if (_2088)\n                {\n                    _2089 = _390.fa_fog_b.y * _2017;\n                }\n                else\n                {\n                    _2089 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _2017, 80.0)))) / _390.fa_fog_b.w;\n                }\n                float _2116;\n                if (abs(_2007) < 0.001000000047497451305389404296875)\n                {\n                    _2116 = _2028;\n                }\n                else\n                {\n                    _2116 = (_2089 - _2056) / _2007;\n                }\n                tau += (_1957 * fast::max(_2116, 0.0));\n            }\n            result = mix(result, _390.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2198);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_626",
            "msl_buffer_n": 7
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 8
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213.fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _568, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _515 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 320,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213.fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _568, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _515 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 320,
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
