{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1996 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467)\n{\n    bool _472 = _467.fa_cl_info.x < 0.0;\n    bool _479;\n    if (!_472)\n    {\n        _479 = _467.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _487;\n    if (!_479)\n    {\n        _487 = _467.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _487 = _479;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _467.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    bool _501;\n    if (!_494)\n    {\n        _501 = _467.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _501 = _494;\n    }\n    if (_501)\n    {\n        return int2(0);\n    }\n    float4 _511 = float4(world_pos, 1.0);\n    float _518 = dot(_467.fa_cl_vpw, _511);\n    if (!(_518 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _540 = float2(dot(_467.fa_cl_vpx, _511), dot(_467.fa_cl_vpy, _511)) / float2(_518);\n    int _544 = int(_467.fa_cl_grid.x);\n    int _548 = int(_467.fa_cl_grid.y);\n    int param = (int(_467.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_467.fa_cl_fwd.xyz, world_pos) + _467.fa_cl_fwd.w, _467.fa_cl_grid.w) / _467.fa_cl_grid.w) * _467.fa_cl_grid.z)), 0, int(_467.fa_cl_info.y) - 1) * _548) + clamp(int(floor(((_540.y * 0.5) + 0.5) * _467.fa_cl_grid.y)), 0, _548 - 1)) * _544)) + clamp(int(floor(((_540.x * 0.5) + 0.5) * _467.fa_cl_grid.x)), 0, _544 - 1);\n    float4 _619 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_619.x), int(_619.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_467.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2544 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _467);\n    fa_cl_slot = _2544.x;\n    fa_cl_local = _2544.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2862 = fa_linear_to_srgb(param);\n        c = _2862;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2870 = fa_srgb_to_linear(param_1);\n            c = _2870;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = fast::normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = fast::normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (bool(i.front_facing))\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _467, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _467.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2901 = fa_tex_fix(param_2, param_3);\n    float4 _3860 = base_t;\n    _3860.x = _2901.x;\n    _3860.y = _2901.y;\n    _3860.z = _2901.z;\n    base_t = _3860;\n    float4 _2915 = (_3860 * _467.fa_base_color) * i.vertex_color;\n    float3 _3762 = i.world_normal;\n    if (_467.fa_maps.z > 0.5)\n    {\n        float param_4 = _467.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2947 = fa_tex_fix(param_6, param_7);\n        float3 _2951 = (_2947 * 2.0) - float3(1.0);\n        float2 _2956 = _2951.xy * _467.fa_maps.x;\n        float3 _3868 = _2951;\n        _3868.x = _2956.x;\n        _3868.y = _2956.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3868;\n        _3762 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _467.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2985 = fa_tex_fix(param_12, param_13);\n    float4 _3871 = mrt;\n    _3871.x = _2985.x;\n    _3871.y = _2985.y;\n    _3871.z = _2985.z;\n    mrt = _3871;\n    float4 _3013 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _467.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3025 = fa_tex_fix(param_16, param_17);\n    float param_18 = _467.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3055 = fa_tex_fix(param_20, param_21);\n    float _3767 = _467.fa_layers_a.x;\n    float _3768 = _467.fa_layers_a.y;\n    float _3771 = _467.fa_layers_a.z;\n    float _3770 = _467.fa_layers_b.w;\n    float _3773 = _467.fa_layers_c.x;\n    if (_467.fa_layers_c.z > 0.5)\n    {\n        if (mod(_467.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3767 *= _3025.y;\n            _3768 *= _3025.z;\n            _3770 *= _3013.w;\n        }\n        if (_467.fa_layers_c.z > 1.5)\n        {\n            _3771 *= mrt.x;\n            _3773 *= mrt.w;\n        }\n    }\n    return Surface{ _2915.xyz, _2915.w, _3762, fast::clamp(_467.fa_pbr.x * _2985.z, 0.0, 1.0), fast::clamp(_467.fa_pbr.y * _2985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_467.fa_maps.y * (_3025.x - 1.0)), _467.fa_emissive.xyz + (_467.fa_model_emissive.xyz * _3055), _3767, _3768, _467.fa_layers_b.xyz, _3770, _3771, _467.fa_layers_a.w, _3773, _467.fa_layers_c.y, _467.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467)\n{\n    int param = (int(_467.fa_cl_info.x) + int(_467.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _467);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _350 = _347.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _356 = _350 < 0.5;\n    float3 l;\n    if (_356)\n    {\n        l = fast::normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / float3(fast::max(_370, 9.9999997473787516355514526367188e-05));\n        float _385 = _370 / fast::max(_341.w, 0.001000000047497451305389404296875);\n        float _391 = fast::clamp(1.0 - (_385 * _385), 0.0, 1.0);\n        atten = _391 * _391;\n        if (_350 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5)\n            {\n                cos_inner = mix(_415, 1.0, 0.25);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, fast::normalize(_405.xyz)));\n        }\n    }\n    int _453;\n    if (_356)\n    {\n        _453 = 0;\n    }\n    else\n    {\n        _453 = (_350 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _347.xyz * atten, atten, 1.0, dist, _453 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _2685 = n < 0;\n    bool _2692;\n    if (!_2685)\n    {\n        _2692 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2692 = _2685;\n    }\n    if (_2692)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2700 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot);\n    bool _2703 = fa_lm.z > 0.5;\n    bool _2709;\n    if (_2703)\n    {\n        int param_1 = _2700;\n        _2709 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2709 = _2703;\n    }\n    if (_2709)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2700;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _703)\n{\n    float _693;\n    if (i == 0)\n    {\n        _693 = _703.fa_shadow_split.x;\n    }\n    else\n    {\n        float _709;\n        if (i == 1)\n        {\n            _709 = _703.fa_shadow_split.y;\n        }\n        else\n        {\n            float _717;\n            if (i == 2)\n            {\n                _717 = _703.fa_shadow_split.z;\n            }\n            else\n            {\n                _717 = _703.fa_shadow_split.w;\n            }\n            _709 = _717;\n        }\n        _693 = _709;\n    }\n    return _693;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _750 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _754;\n    if (conv.x < 0.5)\n    {\n        _754 = _750;\n    }\n    else\n    {\n        _754 = (conv.y * conv.z) / (conv.z - (_750 * (conv.z - conv.y)));\n    }\n    return _754;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _681 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_681), sin(_681)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _800 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _814 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _800;\n            float2 _833 = fa_shadow_vogel(param_3, param_4, param_5) * _814;\n            float2 param_6 = uv + (_833 * _703.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _845 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_845 < (zr - (length(_833) * plane)))\n            {\n                sum += _845;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _889 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _889; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _889;\n        float param_11 = _800;\n        float2 _908 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_908 * _703.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_908) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_889);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    float _950 = fast::max(_703.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _955 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _961 = sqrt(1.0 - (_955 * _955));\n    float _969 = fast::min(_961 / fast::max(_955, 0.20000000298023223876953125), 4.0);\n    float _974;\n    if (_703.fa_shadow_bias.y > 0.0)\n    {\n        _974 = _703.fa_shadow_bias.y;\n    }\n    else\n    {\n        _974 = 1.5 * _703.fa_shadow_info[ci].x;\n    }\n    float4 _999 = _703.fa_shadow_mat[ci] * float4(world + (n * (_974 * _961)), 1.0);\n    float _1006 = _999.x;\n    bool _1009 = _1006 < _703.fa_shadow_rect[ci].x;\n    bool _1018;\n    if (!_1009)\n    {\n        _1018 = _1006 > _703.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1018 = _1009;\n    }\n    bool _1027;\n    if (!_1018)\n    {\n        _1027 = _999.y < _703.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1027 = _1018;\n    }\n    bool _1036;\n    if (!_1027)\n    {\n        _1036 = _999.y > _703.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1036 = _1027;\n    }\n    bool _1043;\n    if (!_1036)\n    {\n        _1043 = _999.z > 1.0;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        return -1.0;\n    }\n    float _1052;\n    if (_703.fa_shadow_bias.x > 0.0)\n    {\n        _1052 = _703.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1052 = 1.5 * _703.fa_shadow_info[ci].x;\n    }\n    float2 param = _999.xy;\n    float4 param_1 = _703.fa_shadow_rect[ci];\n    float param_2 = _999.z - ((_1052 * (1.0 + (0.5 * _969))) / _950);\n    float param_3 = _703.fa_shadow_info[ci].x;\n    float param_4 = _950;\n    float param_5 = _950 * 0.25;\n    float param_6 = ((_703.fa_shadow_info[ci].x * fast::min(_969, 3.0)) * 0.5) / _950;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_703.fa_shadow_cfg.z + 0.5);\n    float param_9 = _703.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    if (_467.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1480 = int(_703.fa_shadow_cfg.x + 0.5);\n    if (_1480 < 1)\n    {\n        return 1.0;\n    }\n    float _1496 = dot(world - _703.fa_shadow_eye.xyz, _703.fa_shadow_fwd.xyz);\n    int param = _1480 - 1;\n    if (_1496 > fa_shadow_split_at(param, _703))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1508 = _1480 > 1;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1496 > _703.fa_shadow_split.x;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 1;\n    }\n    bool _1519 = _1480 > 2;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1496 > _703.fa_shadow_split.y;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 2;\n    }\n    bool _1530 = _1480 > 3;\n    bool _1537;\n    if (_1530)\n    {\n        _1537 = _1496 > _703.fa_shadow_split.z;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1480)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1563 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n        s = _1563;\n        if (_1563 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_703.fa_shadow_cfg.y > 0.0)\n    {\n        float _1588;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1588 = fa_shadow_split_at(param_5, _703);\n        }\n        else\n        {\n            _1588 = _703.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1607 = _703.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _703) - _1588, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1618 = fast::clamp((_1496 - (fa_shadow_split_at(param_7, _703) - _1607)) / _1607, 0.0, 1.0);\n        if (_1618 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1480)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1639 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n                s2 = _1639;\n                if (_1639 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1618);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    bool _1111 = _467.fa_pbr.z < 0.5;\n    bool _1119;\n    if (!_1111)\n    {\n        _1119 = _703.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1119 = _1111;\n    }\n    if (_1119)\n    {\n        return 1.0;\n    }\n    int param = (int(_703.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1132 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1133 = _1132.x;\n    if (_1133 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1142 = int(_1133 + 0.5);\n    int param_1 = _1142;\n    float4 _1146 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1142 + 1;\n    float4 _1151 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1154 = _1146.y;\n    if (_1154 > 0.0)\n    {\n        float _1171 = 1.0 - smoothstep(0.75 * _1154, _1154, length(world - _703.fa_shadow_eye.xyz));\n        fade = _1171;\n        if (_1171 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1146.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1190 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1193 = abs(_1190);\n        float _1195 = _1193.x;\n        float _1197 = _1193.y;\n        bool _1198 = _1195 >= _1197;\n        bool _1206;\n        if (_1198)\n        {\n            _1206 = _1195 >= _1193.z;\n        }\n        else\n        {\n            _1206 = _1198;\n        }\n        int _1207;\n        if (_1206)\n        {\n            _1207 = (_1190.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1220;\n            if (_1197 >= _1193.z)\n            {\n                _1220 = (_1190.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1220 = (_1190.z > 0.0) ? 4 : 5;\n            }\n            _1207 = _1220;\n        }\n        face = _1207;\n    }\n    int _1239 = (_1142 + 2) + (face * 6);\n    int param_4 = _1239;\n    int param_5 = _1239 + 1;\n    int param_6 = _1239 + 3;\n    float4 _1253 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1239 + 4;\n    float4 _1258 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1239 + 5;\n    float4 _1263 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1275 = _1263.x * fast::max(dot(_1253, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1280 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = fast::clamp(dot(n, _1253.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1326 = fast::min(sqrt(1.0 - (_1303 * _1303)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1253, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1329 = _1151.y;\n    float _1331;\n    if (_1329 > 0.0)\n    {\n        _1331 = _1329;\n    }\n    else\n    {\n        _1331 = 1.5 * _1275;\n    }\n    float4 _1351 = float4(world + (n * (_1331 * sqrt(1.0 - (_1280 * _1280)))), 1.0);\n    float _1355 = dot(_1253, _1351);\n    float _1358 = _1263.y;\n    if (_1355 < _1358)\n    {\n        return 1.0;\n    }\n    float2 _1373 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1351), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1351)) / float2(_1355);\n    float _1375 = _1373.x;\n    bool _1378 = _1375 < _1258.x;\n    bool _1387;\n    if (!_1378)\n    {\n        _1387 = _1375 > _1258.z;\n    }\n    else\n    {\n        _1387 = _1378;\n    }\n    bool _1396;\n    if (!_1387)\n    {\n        _1396 = _1373.y < _1258.y;\n    }\n    else\n    {\n        _1396 = _1387;\n    }\n    bool _1405;\n    if (!_1396)\n    {\n        _1405 = _1373.y > _1258.w;\n    }\n    else\n    {\n        _1405 = _1396;\n    }\n    if (_1405)\n    {\n        return 1.0;\n    }\n    float _1411 = _1151.x;\n    float _1413;\n    if (_1411 > 0.0)\n    {\n        _1413 = _1411;\n    }\n    else\n    {\n        _1413 = 1.5 * _1275;\n    }\n    float2 param_10 = _1373;\n    float4 param_11 = _1258;\n    float param_12 = _1355 - (_1413 * (1.0 + (0.5 * _1326)));\n    float param_13 = _1275;\n    float param_14 = 1.0;\n    float param_15 = _1263.z * 0.25;\n    float param_16 = (_1275 * fast::min(_1326, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1358, _1263.z);\n    int param_18 = int(_1146.z + 0.5);\n    float param_19 = _1146.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2571 = fa_lm.z > 0.5;\n    bool _2577;\n    if (_2571)\n    {\n        int param = li;\n        _2577 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2577 = _2571;\n    }\n    if (_2577)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2599 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3738 = _2599.direction;\n    float3 _3733 = _2599.color;\n    float _3740 = _2599.attenuation;\n    float _3735 = _2599.shadow;\n    int _3743 = _2599.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2613 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos);\n        _3735 = _2613;\n        _3733 *= _2613;\n    }\n    else\n    {\n        bool _2624 = _3743 != 0;\n        bool _2630;\n        if (_2624)\n        {\n            _2630 = _3740 > 0.0;\n        }\n        else\n        {\n            _2630 = _2624;\n        }\n        if (_2630)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3738;\n            float _2642 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex);\n            _3735 = _2642;\n            _3733 *= _2642;\n        }\n    }\n    return LightSample{ _3738, _3733, _3740, _3735, _2599._distance, _3743 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _2659 = n < 0;\n    bool _2666;\n    if (!_2659)\n    {\n        _2666 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2666 = _2659;\n    }\n    if (_2666)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1921 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1929 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1932 = int(_1921);\n    int _1935 = int(_1929);\n    float _1945 = _1929 - float(_1935);\n    int _2001 = (_1932 * 9) + _1935;\n    int _2021 = ((_1932 + 1) * 9) + _1935;\n    return mix(mix(_1996[_2001], _1996[_2001 + 1], _1945), mix(_1996[_2021], _1996[_2021 + 1], _1945), _1921 - float(_1932));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3599 = false;\n    float _3600 = 1.0;\n    float _3601 = 1.0;\n    float _3602 = 1.0;\n    float _3603 = 0.0;\n    float _3604 = 0.0;\n    float _3605 = 0.0;\n    float _3606 = 0.0;\n    float _3608 = 1.0;\n    bool _3609 = false;\n    float3 _3610 = float3(0.0);\n    float _3611 = 1.0;\n    float _3612 = 1.0;\n    float _3613 = 1.0;\n    float _3614 = 0.0;\n    float _3615 = 0.0;\n    float3 _3616 = float3(1.0, 0.0, 0.0);\n    float3 _3617 = float3(0.0, 0.0, 1.0);\n    float _3618 = 1.0;\n    float _3619 = 1.0;\n    float _2074 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2078 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2083 = (_2074 != 1.0) || (_2078 != 1.5);\n    bool _2093;\n    if (!_2083)\n    {\n        _2093 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2093 = _2083;\n    }\n    if (_2093)\n    {\n        float _2101 = (_2078 - 1.0) / (_2078 + 1.0);\n        f0 = mix(fast::min(float3(_2101 * _2101) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2074, s.albedo, float3(metallic));\n        _3600 = mix(_2074, 1.0, metallic);\n        _3599 = true;\n    }\n    float _2129 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2129 > 0.0)\n    {\n        float _2137 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3603 = _2129;\n        _3604 = _2137;\n        float _2144 = _2137 * _2137;\n        _3605 = _2144;\n        _3606 = _2144 * _2144;\n        float _2156 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3608 = _2156;\n        _3601 = 1.0 - (_2129 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2156, 0.0, 1.0), 5.0))));\n        _3599 = true;\n    }\n    float3 _2176 = fast::max(s.sheen_color, float3(0.0));\n    float _2185 = fast::max(_2176.x, fast::max(_2176.y, _2176.z));\n    if (_2185 > 0.0)\n    {\n        float _2193 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3609 = true;\n        _3610 = _2176;\n        _3611 = _2193;\n        _3612 = _2193 * _2193;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2193;\n        float _2210 = fa_sheen_albedo(param, param_1);\n        _3614 = _2210;\n        _3613 = 1.0 - fast::min(_2185 * _2210, 1.0);\n        _3599 = true;\n    }\n    _3602 = _3601 * _3613;\n    float _2229 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2229 != 0.0)\n    {\n        float3 _2244 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2244;\n        if (dot(_2244, _2244) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2262 = t;\n        float3 _2263 = fast::normalize(_2262);\n        t = _2263;\n        float3 _2288 = fast::normalize((_2263 * cos(s.anisotropy_rotation)) + ((cross(n, _2263) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3616 = _2288;\n        _3617 = cross(n, _2288);\n        float _2298 = roughness * roughness;\n        float _2304 = mix(_2298, 1.0, _2229 * _2229);\n        bool _2306 = _2229 > 0.0;\n        _3618 = _2306 ? _2304 : _2298;\n        _3619 = _2306 ? _2298 : _2304;\n        _3615 = _2229;\n        _3599 = true;\n    }\n    return FaLayers{ short(_3599), _3600, _3601, _3602, _3603, _3604, _3605, _3606, i.world_normal, _3608, short(_3609), _3610, _3611, _3612, _3613, _3614, _3615, _3616, _3617, _3618, _3619 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1853 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1856 = _1853.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1856 * _1856, exp2((-9.27999973297119140625) * ndv)) * _1856) + _1853.y)) + _1853.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_467.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _467.fa_env_horizon.w)).xyz;\n    }\n    float _1776 = rough * rough;\n    float _1806 = 0.60000002384185791015625 * _1776;\n    return mix(mix(_467.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_467.fa_env_horizon.xyz, _467.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1776)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1806, 0.0500000007450580596923828125 + _1806, d.y))), ((_467.fa_env_sky.xyz + _467.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1776 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2339;\n        if (L.aniso >= 0.0)\n        {\n            _2339 = L.b;\n        }\n        else\n        {\n            _2339 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2339, v), _2339), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2372 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _467, fa_env_tex, fa_env_smp) * ((f0 * _2372.x) + (float3(L.f90) * _2372.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _467, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2427 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _467, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2427.x) + _2427.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _467, fa_env_tex, fa_env_smp) * ((f0 * _1895.x) + float3(_1895.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2466 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2470 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2477 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2466));\n    float3 f0 = _2477;\n    float3 _2481 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2481;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2466;\n    float param_5 = _2470;\n    float3 param_6 = _2477;\n    FaLayers _2498 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2498.on)\n    {\n        FaLayers param_7 = _2498;\n        float3 param_8 = _2481;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2470;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _467, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2481;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2470;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _467, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _2790)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2747 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2747 > bestPower)\n        {\n            bestPower = _2747;\n            best = n;\n        }\n    }\n    float3 lit = (_467.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2776 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _2784;\n        if (dot(s.normal, _2776.direction) > 0.5)\n        {\n            _2784 = 1.0;\n        }\n        else\n        {\n            _2784 = _2790.dark;\n        }\n        lit += ((s.albedo * _2776.color) * _2784);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _467, fa_env_tex, fa_env_smp) * _2790.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _703)\n{\n    if (_703.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1663 = int(_703.fa_shadow_cfg.x + 0.5);\n    float _1673 = dot(world - _703.fa_shadow_eye.xyz, _703.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1678 = _1663 > 0;\n    bool _1687;\n    if (_1678)\n    {\n        int param = _1663 - 1;\n        _1687 = _1673 <= fa_shadow_split_at(param, _703);\n    }\n    else\n    {\n        _1687 = _1678;\n    }\n    if (_1687)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1694 = _1663 > 1;\n        bool _1701;\n        if (_1694)\n        {\n            _1701 = _1673 > _703.fa_shadow_split.x;\n        }\n        else\n        {\n            _1701 = _1694;\n        }\n        if (_1701)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1707 = _1663 > 2;\n        bool _1714;\n        if (_1707)\n        {\n            _1714 = _1673 > _703.fa_shadow_split.y;\n        }\n        else\n        {\n            _1714 = _1707;\n        }\n        if (_1714)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1720 = _1663 > 3;\n        bool _1727;\n        if (_1720)\n        {\n            _1727 = _1673 > _703.fa_shadow_split.z;\n        }\n        else\n        {\n            _1727 = _1720;\n        }\n        if (_1727)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _467 [[buffer(1)]], constant fa_material& _2790 [[buffer(5)]], constant fa_shadows& _703 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3473 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3473 = -_3473;\n    }\n    float3 _3176 = fast::normalize(_467.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n    Surface _3184 = fa_standard_surface(param_1, _467, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3504 = _3184.albedo;\n    float _3505 = _3184.alpha;\n    float3 _3506 = _3184.normal;\n    float _3507 = _3184.metallic;\n    float _3508 = _3184.roughness;\n    float _3509 = _3184.occlusion;\n    float3 _3510 = _3184.emission;\n    float _3511 = _3184.clearcoat;\n    float _3512 = _3184.clearcoat_roughness;\n    float3 _3513 = _3184.sheen_color;\n    float _3514 = _3184.sheen_roughness;\n    float _3515 = _3184.anisotropy;\n    float _3516 = _3184.anisotropy_rotation;\n    float _3517 = _3184.specular;\n    float _3518 = _3184.ior;\n    float3 _3519 = _3184.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n    Surface param_3 = _3184;\n    surface(param_2, param_3);\n    _3504 = param_3.albedo;\n    _3505 = param_3.alpha;\n    _3506 = param_3.normal;\n    _3507 = param_3.metallic;\n    _3508 = param_3.roughness;\n    _3509 = param_3.occlusion;\n    _3510 = param_3.emission;\n    _3511 = param_3.clearcoat;\n    _3512 = param_3.clearcoat_roughness;\n    _3513 = param_3.sheen_color;\n    _3514 = param_3.sheen_roughness;\n    _3515 = param_3.anisotropy;\n    _3516 = param_3.anisotropy_rotation;\n    _3517 = param_3.specular;\n    _3518 = param_3.ior;\n    _3519 = param_3.specular_color;\n    float3 result;\n    if (_467.fa_emissive.w > 0.5)\n    {\n        result = _3504;\n    }\n    else\n    {\n        float3 _3205 = _3506;\n        float3 _3206 = fast::normalize(_3205);\n        _3506 = _3206;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3504, _3505, _3206, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518, _3519 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _2790);\n    }\n    float3 _3221 = result;\n    float3 _3222 = _3221 + _3510;\n    result = _3222;\n    float3 param_6 = _3222;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _703);\n    bool _3231 = _467.fa_fog.w > 0.0;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _467.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        float3 _3247 = in.fa_world_pos - _467.fa_camera_pos.xyz;\n        float _3253 = dot(_3247, _467.fa_fog_c.xyz);\n        bool _3257 = _467.fa_fog_c.w > 0.5;\n        float _3258;\n        if (_3257)\n        {\n            _3258 = _3253;\n        }\n        else\n        {\n            _3258 = length(_3247);\n        }\n        float _3270 = _3258 - _467.fa_fog_b.x;\n        if (_3270 > 0.0)\n        {\n            float _3279 = _467.fa_fog.w * _3270;\n            float tau = _3279 * _3279;\n            if (_467.fa_fog_b.y > 0.0)\n            {\n                float _3295;\n                if (_3257)\n                {\n                    _3295 = in.fa_world_pos.y - (_467.fa_fog_c.y * _3253);\n                }\n                else\n                {\n                    _3295 = _467.fa_camera_pos.y;\n                }\n                float _3316 = mix(_3295, in.fa_world_pos.y, fast::clamp(_467.fa_fog_b.x / _3258, 0.0, 1.0));\n                float _3320 = in.fa_world_pos.y - _3316;\n                float _3325 = _3316 - _467.fa_fog_b.z;\n                float _3330 = in.fa_world_pos.y - _467.fa_fog_b.z;\n                bool _3333 = _3325 <= 0.0;\n                bool _3334 = !_3333;\n                bool _3340;\n                if (_3334)\n                {\n                    _3340 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3340 = _3333;\n                }\n                float _3341;\n                if (_3340)\n                {\n                    _3341 = _467.fa_fog_b.y;\n                }\n                else\n                {\n                    _3341 = _467.fa_fog_b.y * exp(-fast::min(_467.fa_fog_b.w * _3325, 80.0));\n                }\n                bool _3368;\n                if (_3334)\n                {\n                    _3368 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3368 = _3333;\n                }\n                float _3369;\n                if (_3368)\n                {\n                    _3369 = _467.fa_fog_b.y * _3325;\n                }\n                else\n                {\n                    _3369 = (_467.fa_fog_b.y * (1.0 - exp(-fast::min(_467.fa_fog_b.w * _3325, 80.0)))) / _467.fa_fog_b.w;\n                }\n                bool _3394 = _3330 <= 0.0;\n                bool _3401;\n                if (!_3394)\n                {\n                    _3401 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3401 = _3394;\n                }\n                float _3402;\n                if (_3401)\n                {\n                    _3402 = _467.fa_fog_b.y * _3330;\n                }\n                else\n                {\n                    _3402 = (_467.fa_fog_b.y * (1.0 - exp(-fast::min(_467.fa_fog_b.w * _3330, 80.0)))) / _467.fa_fog_b.w;\n                }\n                float _3429;\n                if (abs(_3320) < 0.001000000047497451305389404296875)\n                {\n                    _3429 = _3341;\n                }\n                else\n                {\n                    _3429 = (_3402 - _3369) / _3320;\n                }\n                tau += (_3270 * fast::max(_3429, 0.0));\n            }\n            result = mix(result, _467.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3505);\n    return out;\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_467",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_703",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2790",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1996 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467)\n{\n    bool _472 = _467.fa_cl_info.x < 0.0;\n    bool _479;\n    if (!_472)\n    {\n        _479 = _467.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _487;\n    if (!_479)\n    {\n        _487 = _467.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _487 = _479;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _467.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    bool _501;\n    if (!_494)\n    {\n        _501 = _467.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _501 = _494;\n    }\n    if (_501)\n    {\n        return int2(0);\n    }\n    float4 _511 = float4(world_pos, 1.0);\n    float _518 = dot(_467.fa_cl_vpw, _511);\n    if (!(_518 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _540 = float2(dot(_467.fa_cl_vpx, _511), dot(_467.fa_cl_vpy, _511)) / float2(_518);\n    int _544 = int(_467.fa_cl_grid.x);\n    int _548 = int(_467.fa_cl_grid.y);\n    int param = (int(_467.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_467.fa_cl_fwd.xyz, world_pos) + _467.fa_cl_fwd.w, _467.fa_cl_grid.w) / _467.fa_cl_grid.w) * _467.fa_cl_grid.z)), 0, int(_467.fa_cl_info.y) - 1) * _548) + clamp(int(floor(((_540.y * 0.5) + 0.5) * _467.fa_cl_grid.y)), 0, _548 - 1)) * _544)) + clamp(int(floor(((_540.x * 0.5) + 0.5) * _467.fa_cl_grid.x)), 0, _544 - 1);\n    float4 _619 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_619.x), int(_619.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_467.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2544 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _467);\n    fa_cl_slot = _2544.x;\n    fa_cl_local = _2544.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2862 = fa_linear_to_srgb(param);\n        c = _2862;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2870 = fa_srgb_to_linear(param_1);\n            c = _2870;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = fast::normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = fast::normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (bool(i.front_facing))\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _467, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _467.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2901 = fa_tex_fix(param_2, param_3);\n    float4 _3860 = base_t;\n    _3860.x = _2901.x;\n    _3860.y = _2901.y;\n    _3860.z = _2901.z;\n    base_t = _3860;\n    float4 _2915 = (_3860 * _467.fa_base_color) * i.vertex_color;\n    float3 _3762 = i.world_normal;\n    if (_467.fa_maps.z > 0.5)\n    {\n        float param_4 = _467.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2947 = fa_tex_fix(param_6, param_7);\n        float3 _2951 = (_2947 * 2.0) - float3(1.0);\n        float2 _2956 = _2951.xy * _467.fa_maps.x;\n        float3 _3868 = _2951;\n        _3868.x = _2956.x;\n        _3868.y = _2956.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3868;\n        _3762 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _467.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2985 = fa_tex_fix(param_12, param_13);\n    float4 _3871 = mrt;\n    _3871.x = _2985.x;\n    _3871.y = _2985.y;\n    _3871.z = _2985.z;\n    mrt = _3871;\n    float4 _3013 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _467.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3025 = fa_tex_fix(param_16, param_17);\n    float param_18 = _467.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3055 = fa_tex_fix(param_20, param_21);\n    float _3767 = _467.fa_layers_a.x;\n    float _3768 = _467.fa_layers_a.y;\n    float _3771 = _467.fa_layers_a.z;\n    float _3770 = _467.fa_layers_b.w;\n    float _3773 = _467.fa_layers_c.x;\n    if (_467.fa_layers_c.z > 0.5)\n    {\n        if (mod(_467.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3767 *= _3025.y;\n            _3768 *= _3025.z;\n            _3770 *= _3013.w;\n        }\n        if (_467.fa_layers_c.z > 1.5)\n        {\n            _3771 *= mrt.x;\n            _3773 *= mrt.w;\n        }\n    }\n    return Surface{ _2915.xyz, _2915.w, _3762, fast::clamp(_467.fa_pbr.x * _2985.z, 0.0, 1.0), fast::clamp(_467.fa_pbr.y * _2985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_467.fa_maps.y * (_3025.x - 1.0)), _467.fa_emissive.xyz + (_467.fa_model_emissive.xyz * _3055), _3767, _3768, _467.fa_layers_b.xyz, _3770, _3771, _467.fa_layers_a.w, _3773, _467.fa_layers_c.y, _467.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467)\n{\n    int param = (int(_467.fa_cl_info.x) + int(_467.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _467);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _350 = _347.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _356 = _350 < 0.5;\n    float3 l;\n    if (_356)\n    {\n        l = fast::normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / float3(fast::max(_370, 9.9999997473787516355514526367188e-05));\n        float _385 = _370 / fast::max(_341.w, 0.001000000047497451305389404296875);\n        float _391 = fast::clamp(1.0 - (_385 * _385), 0.0, 1.0);\n        atten = _391 * _391;\n        if (_350 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5)\n            {\n                cos_inner = mix(_415, 1.0, 0.25);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, fast::normalize(_405.xyz)));\n        }\n    }\n    int _453;\n    if (_356)\n    {\n        _453 = 0;\n    }\n    else\n    {\n        _453 = (_350 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _347.xyz * atten, atten, 1.0, dist, _453 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _2685 = n < 0;\n    bool _2692;\n    if (!_2685)\n    {\n        _2692 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2692 = _2685;\n    }\n    if (_2692)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2700 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot);\n    bool _2703 = fa_lm.z > 0.5;\n    bool _2709;\n    if (_2703)\n    {\n        int param_1 = _2700;\n        _2709 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2709 = _2703;\n    }\n    if (_2709)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2700;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _703)\n{\n    float _693;\n    if (i == 0)\n    {\n        _693 = _703.fa_shadow_split.x;\n    }\n    else\n    {\n        float _709;\n        if (i == 1)\n        {\n            _709 = _703.fa_shadow_split.y;\n        }\n        else\n        {\n            float _717;\n            if (i == 2)\n            {\n                _717 = _703.fa_shadow_split.z;\n            }\n            else\n            {\n                _717 = _703.fa_shadow_split.w;\n            }\n            _709 = _717;\n        }\n        _693 = _709;\n    }\n    return _693;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _750 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _754;\n    if (conv.x < 0.5)\n    {\n        _754 = _750;\n    }\n    else\n    {\n        _754 = (conv.y * conv.z) / (conv.z - (_750 * (conv.z - conv.y)));\n    }\n    return _754;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _681 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_681), sin(_681)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _800 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _814 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _800;\n            float2 _833 = fa_shadow_vogel(param_3, param_4, param_5) * _814;\n            float2 param_6 = uv + (_833 * _703.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _845 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_845 < (zr - (length(_833) * plane)))\n            {\n                sum += _845;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _889 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _889; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _889;\n        float param_11 = _800;\n        float2 _908 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_908 * _703.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_908) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_889);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    float _950 = fast::max(_703.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _955 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _961 = sqrt(1.0 - (_955 * _955));\n    float _969 = fast::min(_961 / fast::max(_955, 0.20000000298023223876953125), 4.0);\n    float _974;\n    if (_703.fa_shadow_bias.y > 0.0)\n    {\n        _974 = _703.fa_shadow_bias.y;\n    }\n    else\n    {\n        _974 = 1.5 * _703.fa_shadow_info[ci].x;\n    }\n    float4 _999 = _703.fa_shadow_mat[ci] * float4(world + (n * (_974 * _961)), 1.0);\n    float _1006 = _999.x;\n    bool _1009 = _1006 < _703.fa_shadow_rect[ci].x;\n    bool _1018;\n    if (!_1009)\n    {\n        _1018 = _1006 > _703.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1018 = _1009;\n    }\n    bool _1027;\n    if (!_1018)\n    {\n        _1027 = _999.y < _703.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1027 = _1018;\n    }\n    bool _1036;\n    if (!_1027)\n    {\n        _1036 = _999.y > _703.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1036 = _1027;\n    }\n    bool _1043;\n    if (!_1036)\n    {\n        _1043 = _999.z > 1.0;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        return -1.0;\n    }\n    float _1052;\n    if (_703.fa_shadow_bias.x > 0.0)\n    {\n        _1052 = _703.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1052 = 1.5 * _703.fa_shadow_info[ci].x;\n    }\n    float2 param = _999.xy;\n    float4 param_1 = _703.fa_shadow_rect[ci];\n    float param_2 = _999.z - ((_1052 * (1.0 + (0.5 * _969))) / _950);\n    float param_3 = _703.fa_shadow_info[ci].x;\n    float param_4 = _950;\n    float param_5 = _950 * 0.25;\n    float param_6 = ((_703.fa_shadow_info[ci].x * fast::min(_969, 3.0)) * 0.5) / _950;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_703.fa_shadow_cfg.z + 0.5);\n    float param_9 = _703.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    if (_467.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1480 = int(_703.fa_shadow_cfg.x + 0.5);\n    if (_1480 < 1)\n    {\n        return 1.0;\n    }\n    float _1496 = dot(world - _703.fa_shadow_eye.xyz, _703.fa_shadow_fwd.xyz);\n    int param = _1480 - 1;\n    if (_1496 > fa_shadow_split_at(param, _703))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1508 = _1480 > 1;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1496 > _703.fa_shadow_split.x;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 1;\n    }\n    bool _1519 = _1480 > 2;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1496 > _703.fa_shadow_split.y;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 2;\n    }\n    bool _1530 = _1480 > 3;\n    bool _1537;\n    if (_1530)\n    {\n        _1537 = _1496 > _703.fa_shadow_split.z;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1480)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1563 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n        s = _1563;\n        if (_1563 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_703.fa_shadow_cfg.y > 0.0)\n    {\n        float _1588;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1588 = fa_shadow_split_at(param_5, _703);\n        }\n        else\n        {\n            _1588 = _703.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1607 = _703.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _703) - _1588, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1618 = fast::clamp((_1496 - (fa_shadow_split_at(param_7, _703) - _1607)) / _1607, 0.0, 1.0);\n        if (_1618 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1480)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1639 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex);\n                s2 = _1639;\n                if (_1639 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1618);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex)\n{\n    bool _1111 = _467.fa_pbr.z < 0.5;\n    bool _1119;\n    if (!_1111)\n    {\n        _1119 = _703.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1119 = _1111;\n    }\n    if (_1119)\n    {\n        return 1.0;\n    }\n    int param = (int(_703.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1132 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1133 = _1132.x;\n    if (_1133 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1142 = int(_1133 + 0.5);\n    int param_1 = _1142;\n    float4 _1146 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1142 + 1;\n    float4 _1151 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1154 = _1146.y;\n    if (_1154 > 0.0)\n    {\n        float _1171 = 1.0 - smoothstep(0.75 * _1154, _1154, length(world - _703.fa_shadow_eye.xyz));\n        fade = _1171;\n        if (_1171 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1146.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1190 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1193 = abs(_1190);\n        float _1195 = _1193.x;\n        float _1197 = _1193.y;\n        bool _1198 = _1195 >= _1197;\n        bool _1206;\n        if (_1198)\n        {\n            _1206 = _1195 >= _1193.z;\n        }\n        else\n        {\n            _1206 = _1198;\n        }\n        int _1207;\n        if (_1206)\n        {\n            _1207 = (_1190.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1220;\n            if (_1197 >= _1193.z)\n            {\n                _1220 = (_1190.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1220 = (_1190.z > 0.0) ? 4 : 5;\n            }\n            _1207 = _1220;\n        }\n        face = _1207;\n    }\n    int _1239 = (_1142 + 2) + (face * 6);\n    int param_4 = _1239;\n    int param_5 = _1239 + 1;\n    int param_6 = _1239 + 3;\n    float4 _1253 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1239 + 4;\n    float4 _1258 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1239 + 5;\n    float4 _1263 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1275 = _1263.x * fast::max(dot(_1253, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1280 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = fast::clamp(dot(n, _1253.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1326 = fast::min(sqrt(1.0 - (_1303 * _1303)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1253, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1329 = _1151.y;\n    float _1331;\n    if (_1329 > 0.0)\n    {\n        _1331 = _1329;\n    }\n    else\n    {\n        _1331 = 1.5 * _1275;\n    }\n    float4 _1351 = float4(world + (n * (_1331 * sqrt(1.0 - (_1280 * _1280)))), 1.0);\n    float _1355 = dot(_1253, _1351);\n    float _1358 = _1263.y;\n    if (_1355 < _1358)\n    {\n        return 1.0;\n    }\n    float2 _1373 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1351), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1351)) / float2(_1355);\n    float _1375 = _1373.x;\n    bool _1378 = _1375 < _1258.x;\n    bool _1387;\n    if (!_1378)\n    {\n        _1387 = _1375 > _1258.z;\n    }\n    else\n    {\n        _1387 = _1378;\n    }\n    bool _1396;\n    if (!_1387)\n    {\n        _1396 = _1373.y < _1258.y;\n    }\n    else\n    {\n        _1396 = _1387;\n    }\n    bool _1405;\n    if (!_1396)\n    {\n        _1405 = _1373.y > _1258.w;\n    }\n    else\n    {\n        _1405 = _1396;\n    }\n    if (_1405)\n    {\n        return 1.0;\n    }\n    float _1411 = _1151.x;\n    float _1413;\n    if (_1411 > 0.0)\n    {\n        _1413 = _1411;\n    }\n    else\n    {\n        _1413 = 1.5 * _1275;\n    }\n    float2 param_10 = _1373;\n    float4 param_11 = _1258;\n    float param_12 = _1355 - (_1413 * (1.0 + (0.5 * _1326)));\n    float param_13 = _1275;\n    float param_14 = 1.0;\n    float param_15 = _1263.z * 0.25;\n    float param_16 = (_1275 * fast::min(_1326, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1358, _1263.z);\n    int param_18 = int(_1146.z + 0.5);\n    float param_19 = _1146.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _703, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2571 = fa_lm.z > 0.5;\n    bool _2577;\n    if (_2571)\n    {\n        int param = li;\n        _2577 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2577 = _2571;\n    }\n    if (_2577)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2599 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3738 = _2599.direction;\n    float3 _3733 = _2599.color;\n    float _3740 = _2599.attenuation;\n    float _3735 = _2599.shadow;\n    int _3743 = _2599.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2613 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos);\n        _3735 = _2613;\n        _3733 *= _2613;\n    }\n    else\n    {\n        bool _2624 = _3743 != 0;\n        bool _2630;\n        if (_2624)\n        {\n            _2630 = _3740 > 0.0;\n        }\n        else\n        {\n            _2630 = _2624;\n        }\n        if (_2630)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3738;\n            float _2642 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex);\n            _3735 = _2642;\n            _3733 *= _2642;\n        }\n    }\n    return LightSample{ _3738, _3733, _3740, _3735, _2599._distance, _3743 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _2659 = n < 0;\n    bool _2666;\n    if (!_2659)\n    {\n        _2666 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2666 = _2659;\n    }\n    if (_2666)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1921 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1929 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1932 = int(_1921);\n    int _1935 = int(_1929);\n    float _1945 = _1929 - float(_1935);\n    int _2001 = (_1932 * 9) + _1935;\n    int _2021 = ((_1932 + 1) * 9) + _1935;\n    return mix(mix(_1996[_2001], _1996[_2001 + 1], _1945), mix(_1996[_2021], _1996[_2021 + 1], _1945), _1921 - float(_1932));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3599 = false;\n    float _3600 = 1.0;\n    float _3601 = 1.0;\n    float _3602 = 1.0;\n    float _3603 = 0.0;\n    float _3604 = 0.0;\n    float _3605 = 0.0;\n    float _3606 = 0.0;\n    float _3608 = 1.0;\n    bool _3609 = false;\n    float3 _3610 = float3(0.0);\n    float _3611 = 1.0;\n    float _3612 = 1.0;\n    float _3613 = 1.0;\n    float _3614 = 0.0;\n    float _3615 = 0.0;\n    float3 _3616 = float3(1.0, 0.0, 0.0);\n    float3 _3617 = float3(0.0, 0.0, 1.0);\n    float _3618 = 1.0;\n    float _3619 = 1.0;\n    float _2074 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2078 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2083 = (_2074 != 1.0) || (_2078 != 1.5);\n    bool _2093;\n    if (!_2083)\n    {\n        _2093 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2093 = _2083;\n    }\n    if (_2093)\n    {\n        float _2101 = (_2078 - 1.0) / (_2078 + 1.0);\n        f0 = mix(fast::min(float3(_2101 * _2101) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2074, s.albedo, float3(metallic));\n        _3600 = mix(_2074, 1.0, metallic);\n        _3599 = true;\n    }\n    float _2129 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2129 > 0.0)\n    {\n        float _2137 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3603 = _2129;\n        _3604 = _2137;\n        float _2144 = _2137 * _2137;\n        _3605 = _2144;\n        _3606 = _2144 * _2144;\n        float _2156 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3608 = _2156;\n        _3601 = 1.0 - (_2129 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2156, 0.0, 1.0), 5.0))));\n        _3599 = true;\n    }\n    float3 _2176 = fast::max(s.sheen_color, float3(0.0));\n    float _2185 = fast::max(_2176.x, fast::max(_2176.y, _2176.z));\n    if (_2185 > 0.0)\n    {\n        float _2193 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3609 = true;\n        _3610 = _2176;\n        _3611 = _2193;\n        _3612 = _2193 * _2193;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2193;\n        float _2210 = fa_sheen_albedo(param, param_1);\n        _3614 = _2210;\n        _3613 = 1.0 - fast::min(_2185 * _2210, 1.0);\n        _3599 = true;\n    }\n    _3602 = _3601 * _3613;\n    float _2229 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2229 != 0.0)\n    {\n        float3 _2244 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2244;\n        if (dot(_2244, _2244) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2262 = t;\n        float3 _2263 = fast::normalize(_2262);\n        t = _2263;\n        float3 _2288 = fast::normalize((_2263 * cos(s.anisotropy_rotation)) + ((cross(n, _2263) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3616 = _2288;\n        _3617 = cross(n, _2288);\n        float _2298 = roughness * roughness;\n        float _2304 = mix(_2298, 1.0, _2229 * _2229);\n        bool _2306 = _2229 > 0.0;\n        _3618 = _2306 ? _2304 : _2298;\n        _3619 = _2306 ? _2298 : _2304;\n        _3615 = _2229;\n        _3599 = true;\n    }\n    return FaLayers{ short(_3599), _3600, _3601, _3602, _3603, _3604, _3605, _3606, i.world_normal, _3608, short(_3609), _3610, _3611, _3612, _3613, _3614, _3615, _3616, _3617, _3618, _3619 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1853 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1856 = _1853.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1856 * _1856, exp2((-9.27999973297119140625) * ndv)) * _1856) + _1853.y)) + _1853.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_467.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _467.fa_env_horizon.w)).xyz;\n    }\n    float _1776 = rough * rough;\n    float _1806 = 0.60000002384185791015625 * _1776;\n    return mix(mix(_467.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_467.fa_env_horizon.xyz, _467.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1776)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1806, 0.0500000007450580596923828125 + _1806, d.y))), ((_467.fa_env_sky.xyz + _467.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1776 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2339;\n        if (L.aniso >= 0.0)\n        {\n            _2339 = L.b;\n        }\n        else\n        {\n            _2339 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2339, v), _2339), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2372 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _467, fa_env_tex, fa_env_smp) * ((f0 * _2372.x) + (float3(L.f90) * _2372.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _467, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2427 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _467, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2427.x) + _2427.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _467, fa_env_tex, fa_env_smp) * ((f0 * _1895.x) + float3(_1895.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _467, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2466 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2470 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2477 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2466));\n    float3 f0 = _2477;\n    float3 _2481 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2481;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2466;\n    float param_5 = _2470;\n    float3 param_6 = _2477;\n    FaLayers _2498 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2498.on)\n    {\n        FaLayers param_7 = _2498;\n        float3 param_8 = _2481;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2470;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _467, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2481;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2470;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _467, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _467, thread float4& gl_FragCoord, constant fa_shadows& _703, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _2790)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2747 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2747 > bestPower)\n        {\n            bestPower = _2747;\n            best = n;\n        }\n    }\n    float3 lit = (_467.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2776 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _2784;\n        if (dot(s.normal, _2776.direction) > 0.5)\n        {\n            _2784 = 1.0;\n        }\n        else\n        {\n            _2784 = _2790.dark;\n        }\n        lit += ((s.albedo * _2776.color) * _2784);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _467, fa_env_tex, fa_env_smp) * _2790.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _703)\n{\n    if (_703.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1663 = int(_703.fa_shadow_cfg.x + 0.5);\n    float _1673 = dot(world - _703.fa_shadow_eye.xyz, _703.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1678 = _1663 > 0;\n    bool _1687;\n    if (_1678)\n    {\n        int param = _1663 - 1;\n        _1687 = _1673 <= fa_shadow_split_at(param, _703);\n    }\n    else\n    {\n        _1687 = _1678;\n    }\n    if (_1687)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1694 = _1663 > 1;\n        bool _1701;\n        if (_1694)\n        {\n            _1701 = _1673 > _703.fa_shadow_split.x;\n        }\n        else\n        {\n            _1701 = _1694;\n        }\n        if (_1701)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1707 = _1663 > 2;\n        bool _1714;\n        if (_1707)\n        {\n            _1714 = _1673 > _703.fa_shadow_split.y;\n        }\n        else\n        {\n            _1714 = _1707;\n        }\n        if (_1714)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1720 = _1663 > 3;\n        bool _1727;\n        if (_1720)\n        {\n            _1727 = _1673 > _703.fa_shadow_split.z;\n        }\n        else\n        {\n            _1727 = _1720;\n        }\n        if (_1727)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _467 [[buffer(1)]], constant fa_material& _2790 [[buffer(5)]], constant fa_shadows& _703 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3473 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3473 = -_3473;\n    }\n    float3 _3176 = fast::normalize(_467.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _467, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n    Surface _3184 = fa_standard_surface(param_1, _467, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3504 = _3184.albedo;\n    float _3505 = _3184.alpha;\n    float3 _3506 = _3184.normal;\n    float _3507 = _3184.metallic;\n    float _3508 = _3184.roughness;\n    float _3509 = _3184.occlusion;\n    float3 _3510 = _3184.emission;\n    float _3511 = _3184.clearcoat;\n    float _3512 = _3184.clearcoat_roughness;\n    float3 _3513 = _3184.sheen_color;\n    float _3514 = _3184.sheen_roughness;\n    float _3515 = _3184.anisotropy;\n    float _3516 = _3184.anisotropy_rotation;\n    float _3517 = _3184.specular;\n    float _3518 = _3184.ior;\n    float3 _3519 = _3184.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n    Surface param_3 = _3184;\n    surface(param_2, param_3);\n    _3504 = param_3.albedo;\n    _3505 = param_3.alpha;\n    _3506 = param_3.normal;\n    _3507 = param_3.metallic;\n    _3508 = param_3.roughness;\n    _3509 = param_3.occlusion;\n    _3510 = param_3.emission;\n    _3511 = param_3.clearcoat;\n    _3512 = param_3.clearcoat_roughness;\n    _3513 = param_3.sheen_color;\n    _3514 = param_3.sheen_roughness;\n    _3515 = param_3.anisotropy;\n    _3516 = param_3.anisotropy_rotation;\n    _3517 = param_3.specular;\n    _3518 = param_3.ior;\n    _3519 = param_3.specular_color;\n    float3 result;\n    if (_467.fa_emissive.w > 0.5)\n    {\n        result = _3504;\n    }\n    else\n    {\n        float3 _3205 = _3506;\n        float3 _3206 = fast::normalize(_3205);\n        _3506 = _3206;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3473, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3176, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3504, _3505, _3206, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518, _3519 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _467, gl_FragCoord, _703, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _2790);\n    }\n    float3 _3221 = result;\n    float3 _3222 = _3221 + _3510;\n    result = _3222;\n    float3 param_6 = _3222;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _703);\n    bool _3231 = _467.fa_fog.w > 0.0;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _467.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        float3 _3247 = in.fa_world_pos - _467.fa_camera_pos.xyz;\n        float _3253 = dot(_3247, _467.fa_fog_c.xyz);\n        bool _3257 = _467.fa_fog_c.w > 0.5;\n        float _3258;\n        if (_3257)\n        {\n            _3258 = _3253;\n        }\n        else\n        {\n            _3258 = length(_3247);\n        }\n        float _3270 = _3258 - _467.fa_fog_b.x;\n        if (_3270 > 0.0)\n        {\n            float _3279 = _467.fa_fog.w * _3270;\n            float tau = _3279 * _3279;\n            if (_467.fa_fog_b.y > 0.0)\n            {\n                float _3295;\n                if (_3257)\n                {\n                    _3295 = in.fa_world_pos.y - (_467.fa_fog_c.y * _3253);\n                }\n                else\n                {\n                    _3295 = _467.fa_camera_pos.y;\n                }\n                float _3316 = mix(_3295, in.fa_world_pos.y, fast::clamp(_467.fa_fog_b.x / _3258, 0.0, 1.0));\n                float _3320 = in.fa_world_pos.y - _3316;\n                float _3325 = _3316 - _467.fa_fog_b.z;\n                float _3330 = in.fa_world_pos.y - _467.fa_fog_b.z;\n                bool _3333 = _3325 <= 0.0;\n                bool _3334 = !_3333;\n                bool _3340;\n                if (_3334)\n                {\n                    _3340 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3340 = _3333;\n                }\n                float _3341;\n                if (_3340)\n                {\n                    _3341 = _467.fa_fog_b.y;\n                }\n                else\n                {\n                    _3341 = _467.fa_fog_b.y * exp(-fast::min(_467.fa_fog_b.w * _3325, 80.0));\n                }\n                bool _3368;\n                if (_3334)\n                {\n                    _3368 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3368 = _3333;\n                }\n                float _3369;\n                if (_3368)\n                {\n                    _3369 = _467.fa_fog_b.y * _3325;\n                }\n                else\n                {\n                    _3369 = (_467.fa_fog_b.y * (1.0 - exp(-fast::min(_467.fa_fog_b.w * _3325, 80.0)))) / _467.fa_fog_b.w;\n                }\n                bool _3394 = _3330 <= 0.0;\n                bool _3401;\n                if (!_3394)\n                {\n                    _3401 = _467.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3401 = _3394;\n                }\n                float _3402;\n                if (_3401)\n                {\n                    _3402 = _467.fa_fog_b.y * _3330;\n                }\n                else\n                {\n                    _3402 = (_467.fa_fog_b.y * (1.0 - exp(-fast::min(_467.fa_fog_b.w * _3330, 80.0)))) / _467.fa_fog_b.w;\n                }\n                float _3429;\n                if (abs(_3320) < 0.001000000047497451305389404296875)\n                {\n                    _3429 = _3341;\n                }\n                else\n                {\n                    _3429 = (_3402 - _3369) / _3320;\n                }\n                tau += (_3270 * fast::max(_3429, 0.0));\n            }\n            result = mix(result, _467.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3505);\n    return out;\n}\n\n",
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
            "size": 176,
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
            "inst_name": "_467",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_703",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2790",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
            "size": 176,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
            "size": 176,
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
