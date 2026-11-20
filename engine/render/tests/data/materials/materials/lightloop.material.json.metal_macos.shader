{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1530 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418)\n{\n    bool _423 = _418.fa_cl_info.x < 0.0;\n    bool _430;\n    if (!_423)\n    {\n        _430 = _418.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = _418.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = _418.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = _418.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return int2(0);\n    }\n    float4 _462 = float4(world_pos, 1.0);\n    float _469 = dot(_418.fa_cl_vpw, _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _491 = float2(dot(_418.fa_cl_vpx, _462), dot(_418.fa_cl_vpy, _462)) / float2(_469);\n    int _495 = int(_418.fa_cl_grid.x);\n    int _499 = int(_418.fa_cl_grid.y);\n    int param = (int(_418.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_418.fa_cl_fwd.xyz, world_pos) + _418.fa_cl_fwd.w, _418.fa_cl_grid.w) / _418.fa_cl_grid.w) * _418.fa_cl_grid.z)), 0, int(_418.fa_cl_info.y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5) + 0.5) * _418.fa_cl_grid.y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5) + 0.5) * _418.fa_cl_grid.x)), 0, _495 - 1);\n    float4 _570 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_570.x), int(_570.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_418.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2080 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _418);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _198;\n    if (bool(i.front_facing))\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    float3 _222 = fast::normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    float3 _250 = fast::normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    float3 _253;\n    if (bool(i.front_facing))\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _418, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _418.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2366 = fa_tex_fix(param_2, param_3);\n    float4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    float4 _2380 = (_3279 * _418.fa_base_color) * i.vertex_color;\n    float3 _3213 = i.world_normal;\n    if (_418.fa_maps.z > 0.5)\n    {\n        float param_4 = _418.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2412 = fa_tex_fix(param_6, param_7);\n        float3 _2416 = (_2412 * 2.0) - float3(1.0);\n        float2 _2421 = _2416.xy * _418.fa_maps.x;\n        float3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _418.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2450 = fa_tex_fix(param_12, param_13);\n    float4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    float4 _2478 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _418.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = _418.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = _418.fa_layers_a.x;\n    float _3219 = _418.fa_layers_a.y;\n    float _3222 = _418.fa_layers_a.z;\n    float _3221 = _418.fa_layers_b.w;\n    float _3224 = _418.fa_layers_c.x;\n    if (_418.fa_layers_c.z > 0.5)\n    {\n        if (mod(_418.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (_418.fa_layers_c.z > 1.5)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    return Surface{ _2380.xyz, _2380.w, _3213, fast::clamp(_418.fa_pbr.x * _2450.z, 0.0, 1.0), fast::clamp(_418.fa_pbr.y * _2450.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_418.fa_maps.y * (_2490.x - 1.0)), _418.fa_emissive.xyz + (_418.fa_model_emissive.xyz * _2520), _3218, _3219, _418.fa_layers_b.xyz, _3221, _3222, _418.fa_layers_a.w, _3224, _418.fa_layers_c.y, _418.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418)\n{\n    int param = (int(_418.fa_cl_info.x) + int(_418.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _418);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _306 = _299 < 0.5;\n    float3 l;\n    if (_306)\n    {\n        l = fast::normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / float3(fast::max(_320, 9.9999997473787516355514526367188e-05));\n        float _335 = _320 / fast::max(_290.w, 0.001000000047497451305389404296875);\n        float _341 = fast::clamp(1.0 - (_335 * _335), 0.0, 1.0);\n        atten = _341 * _341;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _355 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            float4 _372 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5)\n            {\n                cos_inner = mix(_365, 1.0, 0.25);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, fast::normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _296.xyz * atten, atten, 1.0, dist, _404 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _654)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = _654.fa_shadow_split.x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = _654.fa_shadow_split.y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = _654.fa_shadow_split.z;\n            }\n            else\n            {\n                _668 = _654.fa_shadow_split.w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex)\n{\n    float _706 = fast::max(_654.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _711 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _717 = sqrt(1.0 - (_711 * _711));\n    float _725 = fast::min(_717 / fast::max(_711, 0.20000000298023223876953125), 4.0);\n    float _730;\n    if (_654.fa_shadow_bias.y > 0.0)\n    {\n        _730 = _654.fa_shadow_bias.y;\n    }\n    else\n    {\n        _730 = 1.5 * _654.fa_shadow_info[ci].x;\n    }\n    float4 _755 = _654.fa_shadow_mat[ci] * float4(world + (n * (_730 * _717)), 1.0);\n    float _762 = _755.x;\n    bool _765 = _762 < _654.fa_shadow_rect[ci].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > _654.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < _654.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > _654.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0;\n    }\n    float _808;\n    if (_654.fa_shadow_bias.x > 0.0)\n    {\n        _808 = _654.fa_shadow_bias.x;\n    }\n    else\n    {\n        _808 = 1.5 * _654.fa_shadow_info[ci].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0 + (0.5 * _725))) / _706);\n    float _836 = ((_654.fa_shadow_info[ci].x * fast::min(_725, 3.0)) * 0.5) / _706;\n    int _845 = int(_654.fa_shadow_cfg.z + 0.5);\n    if (_845 == 1)\n    {\n        float2 param = _755.xy;\n        float4 param_1 = _654.fa_shadow_rect[ci];\n        float _856 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = fast::clamp(((_654.fa_shadow_cfg.w * _706) * 0.25) / _654.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            float2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            float2 param_5 = _755.xy + (_899 * _654.fa_shadow_bias.zw);\n            float4 param_6 = _654.fa_shadow_rect[ci];\n            float _910 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_827 - (sum / cnt), 0.0) * _706) * _654.fa_shadow_cfg.w) / _654.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        float2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _755.xy + (_973 * _654.fa_shadow_bias.zw);\n        float4 param_11 = _654.fa_shadow_rect[ci];\n        float _984 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex)\n{\n    if (_418.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1014 = int(_654.fa_shadow_cfg.x + 0.5);\n    if (_1014 < 1)\n    {\n        return 1.0;\n    }\n    float _1030 = dot(world - _654.fa_shadow_eye.xyz, _654.fa_shadow_fwd.xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param, _654))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > _654.fa_shadow_split.x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > _654.fa_shadow_split.y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > _654.fa_shadow_split.z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _654, fa_shadow_tex);\n        s = _1097;\n        if (_1097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_654.fa_shadow_cfg.y > 0.0)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5, _654);\n        }\n        else\n        {\n            _1122 = _654.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1141 = _654.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _654) - _1122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1152 = fast::clamp((_1030 - (fa_shadow_split_at(param_7, _654) - _1141)) / _1141, 0.0, 1.0);\n        if (_1152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _654, fa_shadow_tex);\n                s2 = _1173;\n                if (_1173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3189 = _2108.direction;\n    float3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    return LightSample{ _3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1455 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1463 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return mix(mix(_1530[_1535], _1530[_1535 + 1], _1479), mix(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0;\n    float _3065 = 1.0;\n    float _3066 = 1.0;\n    float _3067 = 0.0;\n    float _3068 = 0.0;\n    float _3069 = 0.0;\n    float _3070 = 0.0;\n    float _3072 = 1.0;\n    bool _3073 = false;\n    float3 _3074 = float3(0.0);\n    float _3075 = 1.0;\n    float _3076 = 1.0;\n    float _3077 = 1.0;\n    float _3078 = 0.0;\n    float _3079 = 0.0;\n    float3 _3080 = float3(1.0, 0.0, 0.0);\n    float3 _3081 = float3(0.0, 0.0, 1.0);\n    float _3082 = 1.0;\n    float _3083 = 1.0;\n    float _1610 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1614 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1619 = (_1610 != 1.0) || (_1614 != 1.5);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0) / (_1614 + 1.0);\n        f0 = mix(fast::min(float3(_1637 * _1637) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1610, s.albedo, float3(metallic));\n        _3064 = mix(_1610, 1.0, metallic);\n        _3063 = true;\n    }\n    float _1665 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1665 > 0.0)\n    {\n        float _1673 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3072 = _1692;\n        _3065 = 1.0 - (_1665 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1692, 0.0, 1.0), 5.0))));\n        _3063 = true;\n    }\n    float3 _1712 = fast::max(s.sheen_color, float3(0.0));\n    float _1721 = fast::max(_1712.x, fast::max(_1712.y, _1712.z));\n    if (_1721 > 0.0)\n    {\n        float _1729 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0 - fast::min(_1721 * _1746, 1.0);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1765 != 0.0)\n    {\n        float3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1798 = t;\n        float3 _1799 = fast::normalize(_1798);\n        t = _1799;\n        float3 _1824 = fast::normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = mix(_1834, 1.0, _1765 * _1765);\n        bool _1842 = _1765 > 0.0;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    return FaLayers{ short(_3063), _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, short(_3073), _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1387 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1390 = _1387.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1390 * _1390, exp2((-9.27999973297119140625) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_418.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _418.fa_env_horizon.w)).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625 * _1310;\n    return mix(mix(_418.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_418.fa_env_horizon.xyz, _418.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1310)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1340, 0.0500000007450580596923828125 + _1340, d.y))), ((_418.fa_env_sky.xyz + _418.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1310 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1875;\n        if (L.aniso >= 0.0)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1875, v), _1875), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1908 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _418, fa_env_tex, fa_env_smp) * ((f0 * _1908.x) + (float3(L.f90) * _1908.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _418, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1963 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _418, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1429 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _418, fa_env_tex, fa_env_smp) * ((f0 * _1429.x) + float3(_1429.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2002 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2006 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2013 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2002));\n    float3 f0 = _2013;\n    float3 _2017 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2017;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    float3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        float3 param_8 = _2017;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _418, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2017;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _418, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2255)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    float3 lit = (_418.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5)\n        {\n            _2249 = 1.0;\n        }\n        else\n        {\n            _2249 = _2255.dark;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _418, fa_env_tex, fa_env_smp) * _2255.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _654)\n{\n    if (_654.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1197 = int(_654.fa_shadow_cfg.x + 0.5);\n    float _1207 = dot(world - _654.fa_shadow_eye.xyz, _654.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param, _654);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > _654.fa_shadow_split.x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > _654.fa_shadow_split.y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > _654.fa_shadow_split.z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _418 [[buffer(1)]], constant fa_material& _2255 [[buffer(5)]], constant fa_shadows& _654 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2937 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    float3 _2641 = fast::normalize(_418.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n    Surface _2649 = fa_standard_surface(param_1, _418, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    float3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    float3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    float3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    float3 _2983 = _2649.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    float3 result;\n    if (_418.fa_emissive.w > 0.5)\n    {\n        result = _2968;\n    }\n    else\n    {\n        float3 _2670 = _2970;\n        float3 _2671 = fast::normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2255);\n    }\n    float3 _2686 = result;\n    float3 _2687 = _2686 + _2974;\n    result = _2687;\n    float3 param_6 = _2687;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _654);\n    bool _2696 = _418.fa_fog.w > 0.0;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _418.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        float3 _2712 = in.fa_world_pos - _418.fa_camera_pos.xyz;\n        float _2718 = dot(_2712, _418.fa_fog_c.xyz);\n        bool _2722 = _418.fa_fog_c.w > 0.5;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - _418.fa_fog_b.x;\n        if (_2735 > 0.0)\n        {\n            float _2744 = _418.fa_fog.w * _2735;\n            float tau = _2744 * _2744;\n            if (_418.fa_fog_b.y > 0.0)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = in.fa_world_pos.y - (_418.fa_fog_c.y * _2718);\n                }\n                else\n                {\n                    _2760 = _418.fa_camera_pos.y;\n                }\n                float _2781 = mix(_2760, in.fa_world_pos.y, fast::clamp(_418.fa_fog_b.x / _2723, 0.0, 1.0));\n                float _2785 = in.fa_world_pos.y - _2781;\n                float _2790 = _2781 - _418.fa_fog_b.z;\n                float _2795 = in.fa_world_pos.y - _418.fa_fog_b.z;\n                bool _2798 = _2790 <= 0.0;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = _418.fa_fog_b.y;\n                }\n                else\n                {\n                    _2806 = _418.fa_fog_b.y * exp(-fast::min(_418.fa_fog_b.w * _2790, 80.0));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = _418.fa_fog_b.y * _2790;\n                }\n                else\n                {\n                    _2834 = (_418.fa_fog_b.y * (1.0 - exp(-fast::min(_418.fa_fog_b.w * _2790, 80.0)))) / _418.fa_fog_b.w;\n                }\n                bool _2859 = _2795 <= 0.0;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = _418.fa_fog_b.y * _2795;\n                }\n                else\n                {\n                    _2867 = (_418.fa_fog_b.y * (1.0 - exp(-fast::min(_418.fa_fog_b.w * _2795, 80.0)))) / _418.fa_fog_b.w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * fast::max(_2894, 0.0));\n            }\n            result = mix(result, _418.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2969);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_418",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_654",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
            "msl_buffer_n": 5
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
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_389, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1530 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418)\n{\n    bool _423 = _418.fa_cl_info.x < 0.0;\n    bool _430;\n    if (!_423)\n    {\n        _430 = _418.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = _418.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = _418.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = _418.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return int2(0);\n    }\n    float4 _462 = float4(world_pos, 1.0);\n    float _469 = dot(_418.fa_cl_vpw, _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _491 = float2(dot(_418.fa_cl_vpx, _462), dot(_418.fa_cl_vpy, _462)) / float2(_469);\n    int _495 = int(_418.fa_cl_grid.x);\n    int _499 = int(_418.fa_cl_grid.y);\n    int param = (int(_418.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_418.fa_cl_fwd.xyz, world_pos) + _418.fa_cl_fwd.w, _418.fa_cl_grid.w) / _418.fa_cl_grid.w) * _418.fa_cl_grid.z)), 0, int(_418.fa_cl_info.y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5) + 0.5) * _418.fa_cl_grid.y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5) + 0.5) * _418.fa_cl_grid.x)), 0, _495 - 1);\n    float4 _570 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_570.x), int(_570.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_418.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2080 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _418);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _198;\n    if (bool(i.front_facing))\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    float3 _222 = fast::normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    float3 _250 = fast::normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    float3 _253;\n    if (bool(i.front_facing))\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _418, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _418.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2366 = fa_tex_fix(param_2, param_3);\n    float4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    float4 _2380 = (_3279 * _418.fa_base_color) * i.vertex_color;\n    float3 _3213 = i.world_normal;\n    if (_418.fa_maps.z > 0.5)\n    {\n        float param_4 = _418.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2412 = fa_tex_fix(param_6, param_7);\n        float3 _2416 = (_2412 * 2.0) - float3(1.0);\n        float2 _2421 = _2416.xy * _418.fa_maps.x;\n        float3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _418.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2450 = fa_tex_fix(param_12, param_13);\n    float4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    float4 _2478 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _418.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = _418.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = _418.fa_layers_a.x;\n    float _3219 = _418.fa_layers_a.y;\n    float _3222 = _418.fa_layers_a.z;\n    float _3221 = _418.fa_layers_b.w;\n    float _3224 = _418.fa_layers_c.x;\n    if (_418.fa_layers_c.z > 0.5)\n    {\n        if (mod(_418.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (_418.fa_layers_c.z > 1.5)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    return Surface{ _2380.xyz, _2380.w, _3213, fast::clamp(_418.fa_pbr.x * _2450.z, 0.0, 1.0), fast::clamp(_418.fa_pbr.y * _2450.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_418.fa_maps.y * (_2490.x - 1.0)), _418.fa_emissive.xyz + (_418.fa_model_emissive.xyz * _2520), _3218, _3219, _418.fa_layers_b.xyz, _3221, _3222, _418.fa_layers_a.w, _3224, _418.fa_layers_c.y, _418.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418)\n{\n    int param = (int(_418.fa_cl_info.x) + int(_418.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _418);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _306 = _299 < 0.5;\n    float3 l;\n    if (_306)\n    {\n        l = fast::normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / float3(fast::max(_320, 9.9999997473787516355514526367188e-05));\n        float _335 = _320 / fast::max(_290.w, 0.001000000047497451305389404296875);\n        float _341 = fast::clamp(1.0 - (_335 * _335), 0.0, 1.0);\n        atten = _341 * _341;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _355 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            float4 _372 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5)\n            {\n                cos_inner = mix(_365, 1.0, 0.25);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, fast::normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _296.xyz * atten, atten, 1.0, dist, _404 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _654)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = _654.fa_shadow_split.x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = _654.fa_shadow_split.y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = _654.fa_shadow_split.z;\n            }\n            else\n            {\n                _668 = _654.fa_shadow_split.w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex)\n{\n    float _706 = fast::max(_654.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _711 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _717 = sqrt(1.0 - (_711 * _711));\n    float _725 = fast::min(_717 / fast::max(_711, 0.20000000298023223876953125), 4.0);\n    float _730;\n    if (_654.fa_shadow_bias.y > 0.0)\n    {\n        _730 = _654.fa_shadow_bias.y;\n    }\n    else\n    {\n        _730 = 1.5 * _654.fa_shadow_info[ci].x;\n    }\n    float4 _755 = _654.fa_shadow_mat[ci] * float4(world + (n * (_730 * _717)), 1.0);\n    float _762 = _755.x;\n    bool _765 = _762 < _654.fa_shadow_rect[ci].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > _654.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < _654.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > _654.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0;\n    }\n    float _808;\n    if (_654.fa_shadow_bias.x > 0.0)\n    {\n        _808 = _654.fa_shadow_bias.x;\n    }\n    else\n    {\n        _808 = 1.5 * _654.fa_shadow_info[ci].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0 + (0.5 * _725))) / _706);\n    float _836 = ((_654.fa_shadow_info[ci].x * fast::min(_725, 3.0)) * 0.5) / _706;\n    int _845 = int(_654.fa_shadow_cfg.z + 0.5);\n    if (_845 == 1)\n    {\n        float2 param = _755.xy;\n        float4 param_1 = _654.fa_shadow_rect[ci];\n        float _856 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = fast::clamp(((_654.fa_shadow_cfg.w * _706) * 0.25) / _654.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            float2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            float2 param_5 = _755.xy + (_899 * _654.fa_shadow_bias.zw);\n            float4 param_6 = _654.fa_shadow_rect[ci];\n            float _910 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_827 - (sum / cnt), 0.0) * _706) * _654.fa_shadow_cfg.w) / _654.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        float2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _755.xy + (_973 * _654.fa_shadow_bias.zw);\n        float4 param_11 = _654.fa_shadow_rect[ci];\n        float _984 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex)\n{\n    if (_418.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1014 = int(_654.fa_shadow_cfg.x + 0.5);\n    if (_1014 < 1)\n    {\n        return 1.0;\n    }\n    float _1030 = dot(world - _654.fa_shadow_eye.xyz, _654.fa_shadow_fwd.xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param, _654))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > _654.fa_shadow_split.x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > _654.fa_shadow_split.y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > _654.fa_shadow_split.z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _654, fa_shadow_tex);\n        s = _1097;\n        if (_1097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_654.fa_shadow_cfg.y > 0.0)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5, _654);\n        }\n        else\n        {\n            _1122 = _654.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1141 = _654.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _654) - _1122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1152 = fast::clamp((_1030 - (fa_shadow_split_at(param_7, _654) - _1141)) / _1141, 0.0, 1.0);\n        if (_1152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _654, fa_shadow_tex);\n                s2 = _1173;\n                if (_1173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3189 = _2108.direction;\n    float3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    return LightSample{ _3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1455 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1463 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return mix(mix(_1530[_1535], _1530[_1535 + 1], _1479), mix(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0;\n    float _3065 = 1.0;\n    float _3066 = 1.0;\n    float _3067 = 0.0;\n    float _3068 = 0.0;\n    float _3069 = 0.0;\n    float _3070 = 0.0;\n    float _3072 = 1.0;\n    bool _3073 = false;\n    float3 _3074 = float3(0.0);\n    float _3075 = 1.0;\n    float _3076 = 1.0;\n    float _3077 = 1.0;\n    float _3078 = 0.0;\n    float _3079 = 0.0;\n    float3 _3080 = float3(1.0, 0.0, 0.0);\n    float3 _3081 = float3(0.0, 0.0, 1.0);\n    float _3082 = 1.0;\n    float _3083 = 1.0;\n    float _1610 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1614 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1619 = (_1610 != 1.0) || (_1614 != 1.5);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0) / (_1614 + 1.0);\n        f0 = mix(fast::min(float3(_1637 * _1637) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1610, s.albedo, float3(metallic));\n        _3064 = mix(_1610, 1.0, metallic);\n        _3063 = true;\n    }\n    float _1665 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1665 > 0.0)\n    {\n        float _1673 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3072 = _1692;\n        _3065 = 1.0 - (_1665 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1692, 0.0, 1.0), 5.0))));\n        _3063 = true;\n    }\n    float3 _1712 = fast::max(s.sheen_color, float3(0.0));\n    float _1721 = fast::max(_1712.x, fast::max(_1712.y, _1712.z));\n    if (_1721 > 0.0)\n    {\n        float _1729 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0 - fast::min(_1721 * _1746, 1.0);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1765 != 0.0)\n    {\n        float3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1798 = t;\n        float3 _1799 = fast::normalize(_1798);\n        t = _1799;\n        float3 _1824 = fast::normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = mix(_1834, 1.0, _1765 * _1765);\n        bool _1842 = _1765 > 0.0;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    return FaLayers{ short(_3063), _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, short(_3073), _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1387 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1390 = _1387.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1390 * _1390, exp2((-9.27999973297119140625) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_418.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _418.fa_env_horizon.w)).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625 * _1310;\n    return mix(mix(_418.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_418.fa_env_horizon.xyz, _418.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1310)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1340, 0.0500000007450580596923828125 + _1340, d.y))), ((_418.fa_env_sky.xyz + _418.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1310 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1875;\n        if (L.aniso >= 0.0)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1875, v), _1875), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1908 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _418, fa_env_tex, fa_env_smp) * ((f0 * _1908.x) + (float3(L.f90) * _1908.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _418, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1963 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _418, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1429 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _418, fa_env_tex, fa_env_smp) * ((f0 * _1429.x) + float3(_1429.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _418, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2002 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2006 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2013 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2002));\n    float3 f0 = _2013;\n    float3 _2017 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2017;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    float3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        float3 param_8 = _2017;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _418, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2017;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _418, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _418, thread float4& gl_FragCoord, constant fa_shadows& _654, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2255)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    float3 lit = (_418.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5)\n        {\n            _2249 = 1.0;\n        }\n        else\n        {\n            _2249 = _2255.dark;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _418, fa_env_tex, fa_env_smp) * _2255.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _654)\n{\n    if (_654.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1197 = int(_654.fa_shadow_cfg.x + 0.5);\n    float _1207 = dot(world - _654.fa_shadow_eye.xyz, _654.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param, _654);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > _654.fa_shadow_split.x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > _654.fa_shadow_split.y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > _654.fa_shadow_split.z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _418 [[buffer(1)]], constant fa_material& _2255 [[buffer(5)]], constant fa_shadows& _654 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2937 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    float3 _2641 = fast::normalize(_418.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _418, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n    Surface _2649 = fa_standard_surface(param_1, _418, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    float3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    float3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    float3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    float3 _2983 = _2649.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    float3 result;\n    if (_418.fa_emissive.w > 0.5)\n    {\n        result = _2968;\n    }\n    else\n    {\n        float3 _2670 = _2970;\n        float3 _2671 = fast::normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2937, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2641, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _418, gl_FragCoord, _654, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2255);\n    }\n    float3 _2686 = result;\n    float3 _2687 = _2686 + _2974;\n    result = _2687;\n    float3 param_6 = _2687;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _654);\n    bool _2696 = _418.fa_fog.w > 0.0;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _418.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        float3 _2712 = in.fa_world_pos - _418.fa_camera_pos.xyz;\n        float _2718 = dot(_2712, _418.fa_fog_c.xyz);\n        bool _2722 = _418.fa_fog_c.w > 0.5;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - _418.fa_fog_b.x;\n        if (_2735 > 0.0)\n        {\n            float _2744 = _418.fa_fog.w * _2735;\n            float tau = _2744 * _2744;\n            if (_418.fa_fog_b.y > 0.0)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = in.fa_world_pos.y - (_418.fa_fog_c.y * _2718);\n                }\n                else\n                {\n                    _2760 = _418.fa_camera_pos.y;\n                }\n                float _2781 = mix(_2760, in.fa_world_pos.y, fast::clamp(_418.fa_fog_b.x / _2723, 0.0, 1.0));\n                float _2785 = in.fa_world_pos.y - _2781;\n                float _2790 = _2781 - _418.fa_fog_b.z;\n                float _2795 = in.fa_world_pos.y - _418.fa_fog_b.z;\n                bool _2798 = _2790 <= 0.0;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = _418.fa_fog_b.y;\n                }\n                else\n                {\n                    _2806 = _418.fa_fog_b.y * exp(-fast::min(_418.fa_fog_b.w * _2790, 80.0));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = _418.fa_fog_b.y * _2790;\n                }\n                else\n                {\n                    _2834 = (_418.fa_fog_b.y * (1.0 - exp(-fast::min(_418.fa_fog_b.w * _2790, 80.0)))) / _418.fa_fog_b.w;\n                }\n                bool _2859 = _2795 <= 0.0;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = _418.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = _418.fa_fog_b.y * _2795;\n                }\n                else\n                {\n                    _2867 = (_418.fa_fog_b.y * (1.0 - exp(-fast::min(_418.fa_fog_b.w * _2795, 80.0)))) / _418.fa_fog_b.w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * fast::max(_2894, 0.0));\n            }\n            result = mix(result, _418.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2969);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_418",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_654",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
            "msl_buffer_n": 5
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
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
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
