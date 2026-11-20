{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _153.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2745 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    bool _558 = _553.fa_cl_info.x < 0.0;\n    bool _565;\n    if (!_558)\n    {\n        _565 = _553.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = _553.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = _553.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = _553.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return float4(0.0);\n    }\n    float4 _597 = float4(world_pos, 1.0);\n    float _604 = dot(_553.fa_cl_vpw, _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _626 = float2(dot(_553.fa_cl_vpx, _597), dot(_553.fa_cl_vpy, _597)) / float2(_604);\n    int _630 = int(_553.fa_cl_grid.x);\n    int _634 = int(_553.fa_cl_grid.y);\n    int param = (int(_553.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_553.fa_cl_fwd.xyz, world_pos) + _553.fa_cl_fwd.w, _553.fa_cl_grid.w) / _553.fa_cl_grid.w) * _553.fa_cl_grid.z)), 0, int(_553.fa_cl_info.y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5) + 0.5) * _553.fa_cl_grid.y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5) + 0.5) * _553.fa_cl_grid.x)), 0, _630 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    float3 param = world_pos;\n    float4 _710 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _553);\n    return int2(int(_710.x), int(_710.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_553.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3558 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _553);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _309;\n    if (bool(i.front_facing))\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = fast::normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = fast::normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (bool(i.front_facing))\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _553, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _553.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3772 = fa_tex_fix(param_2, param_3);\n    float4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    float4 _3786 = (_5071 * _553.fa_base_color) * i.vertex_color;\n    float3 _4938 = i.world_normal;\n    if (_553.fa_maps.z > 0.5)\n    {\n        float param_4 = _553.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3818 = fa_tex_fix(param_6, param_7);\n        float3 _3821 = (_3818 * 2.0) - float3(1.0);\n        float2 _3826 = _3821.xy * _553.fa_maps.x;\n        float3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _553.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3855 = fa_tex_fix(param_12, param_13);\n    float4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    float4 _3883 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _553.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = _553.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = _553.fa_layers_a.x;\n    float _4944 = _553.fa_layers_a.y;\n    float _4947 = _553.fa_layers_a.z;\n    float _4946 = _553.fa_layers_b.w;\n    float _4949 = _553.fa_layers_c.x;\n    if (_553.fa_layers_c.z > 0.5)\n    {\n        if (mod(_553.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (_553.fa_layers_c.z > 1.5)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    return Surface{ _3786.xyz, _3786.w, _4938, fast::clamp(_553.fa_pbr.x * _3855.z, 0.0, 1.0), fast::clamp(_553.fa_pbr.y * _3855.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_553.fa_maps.y * (_3895.x - 1.0)), _553.fa_emissive.xyz + (_553.fa_model_emissive.xyz * _3925), _4943, _4944, _553.fa_layers_b.xyz, _4946, _4947, _553.fa_layers_a.w, _4949, _553.fa_layers_c.y, _553.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3681)\n{\n    s.emission += ((tint.xyz * tint.w) * _3681.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _791 = rect.zw - rect.xy;\n    float2 _795 = _791 * atlas;\n    float2 _799 = ddx * _795;\n    float2 _803 = ddy * _795;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _791)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _838 = _553.fa_counts.y < 0.5;\n    bool _845;\n    if (!_838)\n    {\n        _845 = _553.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    float3 _851 = dfdx(world_pos);\n    float3 _854 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _858 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _553);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(_553.fa_counts.y + 0.5);\n    int param_1 = _872;\n    float4 _876 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    float4 _888 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _889 = _888.x;\n    int _895 = int(_553.fa_counts.w + 0.5) - 1;\n    int _899 = int(_858.z);\n    float3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        float4 _935 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_935.w + 0.5) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        float4 _950 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _930 + 1;\n        float4 _955 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _930 + 2;\n        float4 _960 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        float3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        float3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = fast::clamp(dot(geo_normal, fast::normalize(_977)) * _935.z, 0.0, 1.0);\n        if (_1018 <= 0.0)\n        {\n            continue;\n        }\n        float _1038 = (fast::clamp((0.5 - abs(_982)) * 10.0, 0.0, 1.0) * _1018) * _935.x;\n        float2 _1046 = float2(_968 + 0.5, 0.5 - _975);\n        float2 _1056 = float2(dot(_963, _851), dot(_970, _851));\n        float2 _1066 = float2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        float4 _1071 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _930 + 3;\n        float4 _1076 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _930 + 4;\n        float4 _1081 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            float4 param_11 = _1076;\n            float2 param_12 = _1046;\n            float2 param_13 = _879;\n            float2 param_14 = _1056;\n            float2 param_15 = _1066;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_889 > 0.5) && (_889 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1117 = fa_dc_to_linear(param_16);\n                float4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1038 * tex_a) * _1071.w, 0.0, 1.0)));\n        if (_1081.z > _1081.x)\n        {\n            float4 param_17 = _1081;\n            float2 param_18 = _1046;\n            float2 param_19 = _879;\n            float2 param_20 = _1056;\n            float2 param_21 = _1066;\n            float4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_889 > 1.5)\n            {\n                float3 param_22 = _1161.xyz;\n                float3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            float3 _1181 = (_1165 * 2.0) - float3(1.0);\n            float2 _1186 = _1181.xy * _935.y;\n            float3 _1208 = (fast::normalize(_963) * _1186.x) + (fast::normalize(_970) * _1186.y);\n            float3 _1211 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1211, fast::normalize((_1211 * fast::max(_1181.z, 0.0500000007450580596923828125)) + (_1208 - (_1211 * dot(_1211, _1208)))), float3(fast::clamp(_1038 * (_1091 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2671 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2678 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return mix(mix(_2745[_2749], _2745[_2749 + 1], _2694), mix(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0;\n    float _4863 = 1.0;\n    float _4864 = 1.0;\n    float _4865 = 0.0;\n    float _4866 = 0.0;\n    float _4867 = 0.0;\n    float _4868 = 0.0;\n    float _4870 = 1.0;\n    bool _4871 = false;\n    float3 _4872 = float3(0.0);\n    float _4873 = 1.0;\n    float _4874 = 1.0;\n    float _4875 = 1.0;\n    float _4876 = 0.0;\n    float _4877 = 0.0;\n    float3 _4878 = float3(1.0, 0.0, 0.0);\n    float3 _4879 = float3(0.0, 0.0, 1.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _2822 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2826 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2831 = (_2822 != 1.0) || (_2826 != 1.5);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0) / (_2826 + 1.0);\n        f0 = mix(fast::min(float3(_2849 * _2849) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2822, s.albedo, float3(metallic));\n        _4862 = mix(_2822, 1.0, metallic);\n        _4861 = true;\n    }\n    float _2877 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2877 > 0.0)\n    {\n        float _2885 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4870 = _2904;\n        _4863 = 1.0 - (_2877 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2904, 0.0, 1.0), 5.0))));\n        _4861 = true;\n    }\n    float3 _2923 = fast::max(s.sheen_color, float3(0.0));\n    float _2932 = fast::max(_2923.x, fast::max(_2923.y, _2923.z));\n    if (_2932 > 0.0)\n    {\n        float _2940 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0 - fast::min(_2932 * _2957, 1.0);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2976 != 0.0)\n    {\n        float3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3008 = t;\n        float3 _3009 = fast::normalize(_3008);\n        t = _3009;\n        float3 _3034 = fast::normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = mix(_3044, 1.0, _2976 * _2976);\n        bool _3052 = _2976 > 0.0;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    return FaLayers{ short(_4861), _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, short(_4871), _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_553.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2428 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2428;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_553.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _553, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _553.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _553, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    int param = (int(_553.fa_cl_info.x) + int(_553.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _553);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _427 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _433 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _436 = _433.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _442 = _436 < 0.5;\n    float3 l;\n    if (_442)\n    {\n        l = fast::normalize(_427.xyz);\n    }\n    else\n    {\n        float3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / float3(fast::max(_456, 9.9999997473787516355514526367188e-05));\n        float _471 = _456 / fast::max(_427.w, 0.001000000047497451305389404296875);\n        float _477 = fast::clamp(1.0 - (_471 * _471), 0.0, 1.0);\n        atten = _477 * _477;\n        if (_436 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _491 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            float4 _507 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5)\n            {\n                cos_inner = mix(_501, 1.0, 0.25);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, fast::normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _433.xyz * atten, atten, 1.0, dist, _539 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1293)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = _1293.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = _1293.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = _1293.fa_shadow_split.z;\n            }\n            else\n            {\n                _1307 = _1293.fa_shadow_split.w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1344;\n    if (conv.x < 0.5)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1390 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1404 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            float2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            float2 param_6 = uv + (_1423 * _1293.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        float2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1498 * _1293.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1479);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    float _1540 = fast::max(_1293.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1545 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1551 = sqrt(1.0 - (_1545 * _1545));\n    float _1558 = fast::min(_1551 / fast::max(_1545, 0.20000000298023223876953125), 4.0);\n    float _1563;\n    if (_1293.fa_shadow_bias.y > 0.0)\n    {\n        _1563 = _1293.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1563 = 1.5 * _1293.fa_shadow_info[ci].x;\n    }\n    float4 _1588 = _1293.fa_shadow_mat[ci] * float4(world + (n * (_1563 * _1551)), 1.0);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < _1293.fa_shadow_rect[ci].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > _1293.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < _1293.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > _1293.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0;\n    }\n    float _1641;\n    if (_1293.fa_shadow_bias.x > 0.0)\n    {\n        _1641 = _1293.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1641 = 1.5 * _1293.fa_shadow_info[ci].x;\n    }\n    float2 param = _1588.xy;\n    float4 param_1 = _1293.fa_shadow_rect[ci];\n    float param_2 = _1588.z - ((_1641 * (1.0 + (0.5 * _1558))) / _1540);\n    float param_3 = _1293.fa_shadow_info[ci].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25;\n    float param_6 = ((_1293.fa_shadow_info[ci].x * fast::min(_1558, 3.0)) * 0.5) / _1540;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1293.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1293.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    if (_553.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2068 = int(_1293.fa_shadow_cfg.x + 0.5);\n    if (_2068 < 1)\n    {\n        return 1.0;\n    }\n    float _2083 = dot(world - _1293.fa_shadow_eye.xyz, _1293.fa_shadow_fwd.xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param, _1293))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > _1293.fa_shadow_split.x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > _1293.fa_shadow_split.y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > _1293.fa_shadow_split.z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n        s = _2150;\n        if (_2150 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1293.fa_shadow_cfg.y > 0.0)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5, _1293);\n        }\n        else\n        {\n            _2175 = _1293.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2194 = _1293.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1293) - _2175, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2205 = fast::clamp((_2083 - (fa_shadow_split_at(param_7, _1293) - _2194)) / _2194, 0.0, 1.0);\n        if (_2205 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n                s2 = _2226;\n                if (_2226 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    bool _1699 = _553.fa_pbr.z < 0.5;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = _1293.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0;\n    }\n    int param = (int(_1293.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1720 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1730 = int(_1721 + 0.5);\n    int param_1 = _1730;\n    float4 _1734 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1730 + 1;\n    float4 _1739 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0)\n    {\n        float _1759 = 1.0 - smoothstep(0.75 * _1742, _1742, length(world - _1293.fa_shadow_eye.xyz));\n        fade = _1759;\n        if (_1759 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1778 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    float4 _1841 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1827 + 4;\n    float4 _1846 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1827 + 5;\n    float4 _1851 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1863 = _1851.x * fast::max(dot(_1841, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1868 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1891 = fast::clamp(dot(n, _1841.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1914 = fast::min(sqrt(1.0 - (_1891 * _1891)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1841, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5 * _1863;\n    }\n    float4 _1939 = float4(world + (n * (_1919 * sqrt(1.0 - (_1868 * _1868)))), 1.0);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0;\n    }\n    float2 _1961 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1939), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1939)) / float2(_1943);\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5 * _1863;\n    }\n    float2 param_10 = _1961;\n    float4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0 + (0.5 * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0;\n    float param_15 = _1851.z * 0.25;\n    float param_16 = (_1863 * fast::min(_1914, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5);\n    float param_19 = _1734.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3585 = fa_lm.z > 0.5;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4923 = _3613.direction;\n    float3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex, fa_world_pos);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    return LightSample{ _4923, _4918, _4925, _4920, _3613._distance, _4928 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3218) * _3218);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3299 = 1.0 / alpha;\n    return ((2.0 + _3299) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3299)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3410) * _3410);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3331);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3331));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3483 = fast::max(dot(L.nc, l), 0.0);\n        float _3489 = fast::max(dot(L.nc, h), 0.0);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3498) * _3498)) * (0.5 / fast::max(mix((2.0 * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3483)) * _3483);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2603 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2606 = _2603.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2606 * _2606, exp2((-9.27999973297119140625) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_553.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _553.fa_env_horizon.w)).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625 * _2457;\n    return mix(mix(_553.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_553.fa_env_horizon.xyz, _553.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2457)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2487, 0.0500000007450580596923828125 + _2487, d.y))), ((_553.fa_env_sky.xyz + _553.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2457 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3085;\n        if (L.aniso >= 0.0)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3085, v), _3085), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3118 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _553, fa_env_smp, fa_env_tex) * ((f0 * _3118.x) + (float3(L.f90) * _3118.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _553, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3173 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _553, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2645 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _553, fa_env_smp, fa_env_tex) * ((f0 * _2645.x) + float3(_2645.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1293)\n{\n    if (_1293.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2250 = int(_1293.fa_shadow_cfg.x + 0.5);\n    float _2260 = dot(world - _1293.fa_shadow_eye.xyz, _1293.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param, _1293);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > _1293.fa_shadow_split.x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > _1293.fa_shadow_split.y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > _1293.fa_shadow_split.z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _553 [[buffer(1)]], constant fa_material& _3681 [[buffer(5)]], constant fa_shadows& _1293 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4640 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    float3 _4065 = fast::normalize(_553.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _553, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface _4073 = fa_standard_surface(param_1, _553, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    float3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    float3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    float3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    float3 _4686 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface param_3 = _4073;\n    surface(param_2, param_3, tint, _3681);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4640;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _553, fa_decal_tex, fa_env_smp);\n    _4671 = param_6;\n    _4673 = param_7;\n    float3 result;\n    if (_553.fa_emissive.w > 0.5)\n    {\n        result = _4671;\n    }\n    else\n    {\n        float3 _4112 = fast::normalize(_4673);\n        float _4119 = fast::clamp(_4674, 0.0, 1.0);\n        float _4123 = fast::clamp(_4675, 0.0500000007450580596923828125, 1.0);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = fast::max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05);\n        float3 _4142 = _4671 * (1.0 - _4119);\n        float3 _4149 = mix(float3(0.039999999105930328369140625), _4671, float3(_4119));\n        float3 f0 = _4149;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686 };\n        float3 param_10 = _4112;\n        float3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        float3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4112;\n        float3 lit = (fa_indirect_diffuse(param_15, _553, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _553, fa_cl_ndir, fa_cl_slot);\n            bool _4203 = in.fa_lm.z > 0.5;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4845 = _4221.direction;\n            float _4229 = fast::max(dot(_4112, _4845), 0.0);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            float3 _4240 = fast::normalize(_4845 + _4065);\n            float _4245 = fast::max(dot(_4112, _4240), 0.0);\n            float _4250 = fast::max(dot(_4065, _4240), 0.0);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                float3 param_22 = _4142;\n                float3 param_23 = f0;\n                float3 param_24 = _4112;\n                float3 param_25 = _4065;\n                float3 param_26 = _4845;\n                float3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0)) + 1.0;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4250, 5.0))) * (((_4131 / ((3.1415927410125732421875 * _4298) * _4298)) * (0.5 / fast::max(mix((2.0 * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            float3 param_37 = _4112;\n            float3 param_38 = _4065;\n            float3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _553, fa_env_smp, fa_env_tex) * _4676);\n        }\n        else\n        {\n            float3 param_41 = _4112;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _553, fa_env_smp, fa_env_tex) * _4676);\n        }\n        result = lit;\n    }\n    float3 _4391 = result;\n    float3 _4392 = _4391 + _4677;\n    result = _4392;\n    float3 param_45 = _4392;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1293);\n    bool _4401 = _553.fa_fog.w > 0.0;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = _553.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        float3 _4417 = in.fa_world_pos - _553.fa_camera_pos.xyz;\n        float _4423 = dot(_4417, _553.fa_fog_c.xyz);\n        bool _4427 = _553.fa_fog_c.w > 0.5;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - _553.fa_fog_b.x;\n        if (_4440 > 0.0)\n        {\n            float _4449 = _553.fa_fog.w * _4440;\n            float tau = _4449 * _4449;\n            if (_553.fa_fog_b.y > 0.0)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = in.fa_world_pos.y - (_553.fa_fog_c.y * _4423);\n                }\n                else\n                {\n                    _4465 = _553.fa_camera_pos.y;\n                }\n                float _4486 = mix(_4465, in.fa_world_pos.y, fast::clamp(_553.fa_fog_b.x / _4428, 0.0, 1.0));\n                float _4490 = in.fa_world_pos.y - _4486;\n                float _4495 = _4486 - _553.fa_fog_b.z;\n                float _4500 = in.fa_world_pos.y - _553.fa_fog_b.z;\n                bool _4503 = _4495 <= 0.0;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = _553.fa_fog_b.y;\n                }\n                else\n                {\n                    _4511 = _553.fa_fog_b.y * exp(-fast::min(_553.fa_fog_b.w * _4495, 80.0));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = _553.fa_fog_b.y * _4495;\n                }\n                else\n                {\n                    _4539 = (_553.fa_fog_b.y * (1.0 - exp(-fast::min(_553.fa_fog_b.w * _4495, 80.0)))) / _553.fa_fog_b.w;\n                }\n                bool _4564 = _4500 <= 0.0;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = _553.fa_fog_b.y * _4500;\n                }\n                else\n                {\n                    _4572 = (_553.fa_fog_b.y * (1.0 - exp(-fast::min(_553.fa_fog_b.w * _4500, 80.0)))) / _553.fa_fog_b.w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * fast::max(_4599, 0.0));\n            }\n            result = mix(result, _553.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4672);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_553",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1293",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3681",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2745 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    bool _558 = _553.fa_cl_info.x < 0.0;\n    bool _565;\n    if (!_558)\n    {\n        _565 = _553.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = _553.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = _553.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = _553.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return float4(0.0);\n    }\n    float4 _597 = float4(world_pos, 1.0);\n    float _604 = dot(_553.fa_cl_vpw, _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _626 = float2(dot(_553.fa_cl_vpx, _597), dot(_553.fa_cl_vpy, _597)) / float2(_604);\n    int _630 = int(_553.fa_cl_grid.x);\n    int _634 = int(_553.fa_cl_grid.y);\n    int param = (int(_553.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_553.fa_cl_fwd.xyz, world_pos) + _553.fa_cl_fwd.w, _553.fa_cl_grid.w) / _553.fa_cl_grid.w) * _553.fa_cl_grid.z)), 0, int(_553.fa_cl_info.y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5) + 0.5) * _553.fa_cl_grid.y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5) + 0.5) * _553.fa_cl_grid.x)), 0, _630 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    float3 param = world_pos;\n    float4 _710 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _553);\n    return int2(int(_710.x), int(_710.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_553.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3558 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _553);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _309;\n    if (bool(i.front_facing))\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = fast::normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = fast::normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (bool(i.front_facing))\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _553, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _553.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3772 = fa_tex_fix(param_2, param_3);\n    float4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    float4 _3786 = (_5071 * _553.fa_base_color) * i.vertex_color;\n    float3 _4938 = i.world_normal;\n    if (_553.fa_maps.z > 0.5)\n    {\n        float param_4 = _553.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3818 = fa_tex_fix(param_6, param_7);\n        float3 _3821 = (_3818 * 2.0) - float3(1.0);\n        float2 _3826 = _3821.xy * _553.fa_maps.x;\n        float3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _553.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3855 = fa_tex_fix(param_12, param_13);\n    float4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    float4 _3883 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _553.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = _553.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = _553.fa_layers_a.x;\n    float _4944 = _553.fa_layers_a.y;\n    float _4947 = _553.fa_layers_a.z;\n    float _4946 = _553.fa_layers_b.w;\n    float _4949 = _553.fa_layers_c.x;\n    if (_553.fa_layers_c.z > 0.5)\n    {\n        if (mod(_553.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (_553.fa_layers_c.z > 1.5)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    return Surface{ _3786.xyz, _3786.w, _4938, fast::clamp(_553.fa_pbr.x * _3855.z, 0.0, 1.0), fast::clamp(_553.fa_pbr.y * _3855.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_553.fa_maps.y * (_3895.x - 1.0)), _553.fa_emissive.xyz + (_553.fa_model_emissive.xyz * _3925), _4943, _4944, _553.fa_layers_b.xyz, _4946, _4947, _553.fa_layers_a.w, _4949, _553.fa_layers_c.y, _553.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3681)\n{\n    s.emission += ((tint.xyz * tint.w) * _3681.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _791 = rect.zw - rect.xy;\n    float2 _795 = _791 * atlas;\n    float2 _799 = ddx * _795;\n    float2 _803 = ddy * _795;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _791)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _838 = _553.fa_counts.y < 0.5;\n    bool _845;\n    if (!_838)\n    {\n        _845 = _553.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    float3 _851 = dfdx(world_pos);\n    float3 _854 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _858 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _553);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(_553.fa_counts.y + 0.5);\n    int param_1 = _872;\n    float4 _876 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    float4 _888 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _889 = _888.x;\n    int _895 = int(_553.fa_counts.w + 0.5) - 1;\n    int _899 = int(_858.z);\n    float3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        float4 _935 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_935.w + 0.5) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        float4 _950 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _930 + 1;\n        float4 _955 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _930 + 2;\n        float4 _960 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        float3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        float3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = fast::clamp(dot(geo_normal, fast::normalize(_977)) * _935.z, 0.0, 1.0);\n        if (_1018 <= 0.0)\n        {\n            continue;\n        }\n        float _1038 = (fast::clamp((0.5 - abs(_982)) * 10.0, 0.0, 1.0) * _1018) * _935.x;\n        float2 _1046 = float2(_968 + 0.5, 0.5 - _975);\n        float2 _1056 = float2(dot(_963, _851), dot(_970, _851));\n        float2 _1066 = float2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        float4 _1071 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _930 + 3;\n        float4 _1076 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _930 + 4;\n        float4 _1081 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            float4 param_11 = _1076;\n            float2 param_12 = _1046;\n            float2 param_13 = _879;\n            float2 param_14 = _1056;\n            float2 param_15 = _1066;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_889 > 0.5) && (_889 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1117 = fa_dc_to_linear(param_16);\n                float4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1038 * tex_a) * _1071.w, 0.0, 1.0)));\n        if (_1081.z > _1081.x)\n        {\n            float4 param_17 = _1081;\n            float2 param_18 = _1046;\n            float2 param_19 = _879;\n            float2 param_20 = _1056;\n            float2 param_21 = _1066;\n            float4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_889 > 1.5)\n            {\n                float3 param_22 = _1161.xyz;\n                float3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            float3 _1181 = (_1165 * 2.0) - float3(1.0);\n            float2 _1186 = _1181.xy * _935.y;\n            float3 _1208 = (fast::normalize(_963) * _1186.x) + (fast::normalize(_970) * _1186.y);\n            float3 _1211 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1211, fast::normalize((_1211 * fast::max(_1181.z, 0.0500000007450580596923828125)) + (_1208 - (_1211 * dot(_1211, _1208)))), float3(fast::clamp(_1038 * (_1091 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2671 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2678 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return mix(mix(_2745[_2749], _2745[_2749 + 1], _2694), mix(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0;\n    float _4863 = 1.0;\n    float _4864 = 1.0;\n    float _4865 = 0.0;\n    float _4866 = 0.0;\n    float _4867 = 0.0;\n    float _4868 = 0.0;\n    float _4870 = 1.0;\n    bool _4871 = false;\n    float3 _4872 = float3(0.0);\n    float _4873 = 1.0;\n    float _4874 = 1.0;\n    float _4875 = 1.0;\n    float _4876 = 0.0;\n    float _4877 = 0.0;\n    float3 _4878 = float3(1.0, 0.0, 0.0);\n    float3 _4879 = float3(0.0, 0.0, 1.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _2822 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2826 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2831 = (_2822 != 1.0) || (_2826 != 1.5);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0) / (_2826 + 1.0);\n        f0 = mix(fast::min(float3(_2849 * _2849) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2822, s.albedo, float3(metallic));\n        _4862 = mix(_2822, 1.0, metallic);\n        _4861 = true;\n    }\n    float _2877 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2877 > 0.0)\n    {\n        float _2885 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4870 = _2904;\n        _4863 = 1.0 - (_2877 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2904, 0.0, 1.0), 5.0))));\n        _4861 = true;\n    }\n    float3 _2923 = fast::max(s.sheen_color, float3(0.0));\n    float _2932 = fast::max(_2923.x, fast::max(_2923.y, _2923.z));\n    if (_2932 > 0.0)\n    {\n        float _2940 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0 - fast::min(_2932 * _2957, 1.0);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2976 != 0.0)\n    {\n        float3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3008 = t;\n        float3 _3009 = fast::normalize(_3008);\n        t = _3009;\n        float3 _3034 = fast::normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = mix(_3044, 1.0, _2976 * _2976);\n        bool _3052 = _2976 > 0.0;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    return FaLayers{ short(_4861), _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, short(_4871), _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_553.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2428 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2428;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_553.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _553, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _553.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _553, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553)\n{\n    int param = (int(_553.fa_cl_info.x) + int(_553.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _553);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _427 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _433 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _436 = _433.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _442 = _436 < 0.5;\n    float3 l;\n    if (_442)\n    {\n        l = fast::normalize(_427.xyz);\n    }\n    else\n    {\n        float3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / float3(fast::max(_456, 9.9999997473787516355514526367188e-05));\n        float _471 = _456 / fast::max(_427.w, 0.001000000047497451305389404296875);\n        float _477 = fast::clamp(1.0 - (_471 * _471), 0.0, 1.0);\n        atten = _477 * _477;\n        if (_436 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _491 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            float4 _507 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5)\n            {\n                cos_inner = mix(_501, 1.0, 0.25);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, fast::normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _433.xyz * atten, atten, 1.0, dist, _539 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1293)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = _1293.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = _1293.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = _1293.fa_shadow_split.z;\n            }\n            else\n            {\n                _1307 = _1293.fa_shadow_split.w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1344;\n    if (conv.x < 0.5)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1390 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1404 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            float2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            float2 param_6 = uv + (_1423 * _1293.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        float2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1498 * _1293.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1479);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    float _1540 = fast::max(_1293.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1545 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1551 = sqrt(1.0 - (_1545 * _1545));\n    float _1558 = fast::min(_1551 / fast::max(_1545, 0.20000000298023223876953125), 4.0);\n    float _1563;\n    if (_1293.fa_shadow_bias.y > 0.0)\n    {\n        _1563 = _1293.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1563 = 1.5 * _1293.fa_shadow_info[ci].x;\n    }\n    float4 _1588 = _1293.fa_shadow_mat[ci] * float4(world + (n * (_1563 * _1551)), 1.0);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < _1293.fa_shadow_rect[ci].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > _1293.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < _1293.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > _1293.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0;\n    }\n    float _1641;\n    if (_1293.fa_shadow_bias.x > 0.0)\n    {\n        _1641 = _1293.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1641 = 1.5 * _1293.fa_shadow_info[ci].x;\n    }\n    float2 param = _1588.xy;\n    float4 param_1 = _1293.fa_shadow_rect[ci];\n    float param_2 = _1588.z - ((_1641 * (1.0 + (0.5 * _1558))) / _1540);\n    float param_3 = _1293.fa_shadow_info[ci].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25;\n    float param_6 = ((_1293.fa_shadow_info[ci].x * fast::min(_1558, 3.0)) * 0.5) / _1540;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1293.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1293.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    if (_553.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2068 = int(_1293.fa_shadow_cfg.x + 0.5);\n    if (_2068 < 1)\n    {\n        return 1.0;\n    }\n    float _2083 = dot(world - _1293.fa_shadow_eye.xyz, _1293.fa_shadow_fwd.xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param, _1293))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > _1293.fa_shadow_split.x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > _1293.fa_shadow_split.y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > _1293.fa_shadow_split.z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n        s = _2150;\n        if (_2150 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1293.fa_shadow_cfg.y > 0.0)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5, _1293);\n        }\n        else\n        {\n            _2175 = _1293.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2194 = _1293.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1293) - _2175, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2205 = fast::clamp((_2083 - (fa_shadow_split_at(param_7, _1293) - _2194)) / _2194, 0.0, 1.0);\n        if (_2205 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex);\n                s2 = _2226;\n                if (_2226 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex)\n{\n    bool _1699 = _553.fa_pbr.z < 0.5;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = _1293.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0;\n    }\n    int param = (int(_1293.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1720 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1730 = int(_1721 + 0.5);\n    int param_1 = _1730;\n    float4 _1734 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1730 + 1;\n    float4 _1739 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0)\n    {\n        float _1759 = 1.0 - smoothstep(0.75 * _1742, _1742, length(world - _1293.fa_shadow_eye.xyz));\n        fade = _1759;\n        if (_1759 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1778 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    float4 _1841 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1827 + 4;\n    float4 _1846 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1827 + 5;\n    float4 _1851 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1863 = _1851.x * fast::max(dot(_1841, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1868 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1891 = fast::clamp(dot(n, _1841.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1914 = fast::min(sqrt(1.0 - (_1891 * _1891)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1841, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5 * _1863;\n    }\n    float4 _1939 = float4(world + (n * (_1919 * sqrt(1.0 - (_1868 * _1868)))), 1.0);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0;\n    }\n    float2 _1961 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1939), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1939)) / float2(_1943);\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5 * _1863;\n    }\n    float2 param_10 = _1961;\n    float4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0 + (0.5 * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0;\n    float param_15 = _1851.z * 0.25;\n    float param_16 = (_1863 * fast::min(_1914, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5);\n    float param_19 = _1734.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1293, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _553, thread float4& gl_FragCoord, constant fa_shadows& _1293, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3585 = fa_lm.z > 0.5;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4923 = _3613.direction;\n    float3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex, fa_world_pos);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    return LightSample{ _4923, _4918, _4925, _4920, _3613._distance, _4928 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3218) * _3218);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3299 = 1.0 / alpha;\n    return ((2.0 + _3299) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3299)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3410) * _3410);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3331);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3331));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3483 = fast::max(dot(L.nc, l), 0.0);\n        float _3489 = fast::max(dot(L.nc, h), 0.0);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3498) * _3498)) * (0.5 / fast::max(mix((2.0 * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3483)) * _3483);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2603 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2606 = _2603.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2606 * _2606, exp2((-9.27999973297119140625) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_553.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _553.fa_env_horizon.w)).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625 * _2457;\n    return mix(mix(_553.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_553.fa_env_horizon.xyz, _553.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2457)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2487, 0.0500000007450580596923828125 + _2487, d.y))), ((_553.fa_env_sky.xyz + _553.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2457 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3085;\n        if (L.aniso >= 0.0)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3085, v), _3085), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3118 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _553, fa_env_smp, fa_env_tex) * ((f0 * _3118.x) + (float3(L.f90) * _3118.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _553, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3173 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _553, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _553, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2645 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _553, fa_env_smp, fa_env_tex) * ((f0 * _2645.x) + float3(_2645.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1293)\n{\n    if (_1293.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2250 = int(_1293.fa_shadow_cfg.x + 0.5);\n    float _2260 = dot(world - _1293.fa_shadow_eye.xyz, _1293.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param, _1293);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > _1293.fa_shadow_split.x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > _1293.fa_shadow_split.y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > _1293.fa_shadow_split.z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _553 [[buffer(1)]], constant fa_material& _3681 [[buffer(5)]], constant fa_shadows& _1293 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4640 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    float3 _4065 = fast::normalize(_553.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _553, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface _4073 = fa_standard_surface(param_1, _553, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    float3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    float3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    float3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    float3 _4686 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface param_3 = _4073;\n    surface(param_2, param_3, tint, _3681);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4640;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _553, fa_decal_tex, fa_env_smp);\n    _4671 = param_6;\n    _4673 = param_7;\n    float3 result;\n    if (_553.fa_emissive.w > 0.5)\n    {\n        result = _4671;\n    }\n    else\n    {\n        float3 _4112 = fast::normalize(_4673);\n        float _4119 = fast::clamp(_4674, 0.0, 1.0);\n        float _4123 = fast::clamp(_4675, 0.0500000007450580596923828125, 1.0);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = fast::max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05);\n        float3 _4142 = _4671 * (1.0 - _4119);\n        float3 _4149 = mix(float3(0.039999999105930328369140625), _4671, float3(_4119));\n        float3 f0 = _4149;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4640, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686 };\n        float3 param_10 = _4112;\n        float3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        float3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4112;\n        float3 lit = (fa_indirect_diffuse(param_15, _553, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _553, fa_cl_ndir, fa_cl_slot);\n            bool _4203 = in.fa_lm.z > 0.5;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _553, gl_FragCoord, _1293, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4845 = _4221.direction;\n            float _4229 = fast::max(dot(_4112, _4845), 0.0);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            float3 _4240 = fast::normalize(_4845 + _4065);\n            float _4245 = fast::max(dot(_4112, _4240), 0.0);\n            float _4250 = fast::max(dot(_4065, _4240), 0.0);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                float3 param_22 = _4142;\n                float3 param_23 = f0;\n                float3 param_24 = _4112;\n                float3 param_25 = _4065;\n                float3 param_26 = _4845;\n                float3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0)) + 1.0;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4250, 5.0))) * (((_4131 / ((3.1415927410125732421875 * _4298) * _4298)) * (0.5 / fast::max(mix((2.0 * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            float3 param_37 = _4112;\n            float3 param_38 = _4065;\n            float3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _553, fa_env_smp, fa_env_tex) * _4676);\n        }\n        else\n        {\n            float3 param_41 = _4112;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _553, fa_env_smp, fa_env_tex) * _4676);\n        }\n        result = lit;\n    }\n    float3 _4391 = result;\n    float3 _4392 = _4391 + _4677;\n    result = _4392;\n    float3 param_45 = _4392;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1293);\n    bool _4401 = _553.fa_fog.w > 0.0;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = _553.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        float3 _4417 = in.fa_world_pos - _553.fa_camera_pos.xyz;\n        float _4423 = dot(_4417, _553.fa_fog_c.xyz);\n        bool _4427 = _553.fa_fog_c.w > 0.5;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - _553.fa_fog_b.x;\n        if (_4440 > 0.0)\n        {\n            float _4449 = _553.fa_fog.w * _4440;\n            float tau = _4449 * _4449;\n            if (_553.fa_fog_b.y > 0.0)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = in.fa_world_pos.y - (_553.fa_fog_c.y * _4423);\n                }\n                else\n                {\n                    _4465 = _553.fa_camera_pos.y;\n                }\n                float _4486 = mix(_4465, in.fa_world_pos.y, fast::clamp(_553.fa_fog_b.x / _4428, 0.0, 1.0));\n                float _4490 = in.fa_world_pos.y - _4486;\n                float _4495 = _4486 - _553.fa_fog_b.z;\n                float _4500 = in.fa_world_pos.y - _553.fa_fog_b.z;\n                bool _4503 = _4495 <= 0.0;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = _553.fa_fog_b.y;\n                }\n                else\n                {\n                    _4511 = _553.fa_fog_b.y * exp(-fast::min(_553.fa_fog_b.w * _4495, 80.0));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = _553.fa_fog_b.y * _4495;\n                }\n                else\n                {\n                    _4539 = (_553.fa_fog_b.y * (1.0 - exp(-fast::min(_553.fa_fog_b.w * _4495, 80.0)))) / _553.fa_fog_b.w;\n                }\n                bool _4564 = _4500 <= 0.0;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = _553.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = _553.fa_fog_b.y * _4500;\n                }\n                else\n                {\n                    _4572 = (_553.fa_fog_b.y * (1.0 - exp(-fast::min(_553.fa_fog_b.w * _4500, 80.0)))) / _553.fa_fog_b.w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * fast::max(_4599, 0.0));\n            }\n            result = mix(result, _553.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4672);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_553",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1293",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3681",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253.fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253.fa_layers_a.x;\n    float _739 = _253.fa_layers_a.y;\n    float _742 = _253.fa_layers_a.z;\n    float _741 = _253.fa_layers_b.w;\n    float _744 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _733, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _738, _739, _253.fa_layers_b.xyz, _741, _742, _253.fa_layers_a.w, _744, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _644 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    float4 _310 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_158.fa_light_vp * _310).z;\n    fa_pre_r0 = float3(_158.fa_light_vp[0].x, _158.fa_light_vp[1].x, _158.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158.fa_light_vp[0].y, _158.fa_light_vp[1].y, _158.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158.fa_light_vp[0].z, _158.fa_light_vp[1].z, _158.fa_light_vp[2].z);\n    gl_Position = _158.fa_view_proj * _310;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253.fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253.fa_layers_a.x;\n    float _739 = _253.fa_layers_a.y;\n    float _742 = _253.fa_layers_a.z;\n    float _741 = _253.fa_layers_b.w;\n    float _744 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _733, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _738, _739, _253.fa_layers_b.xyz, _741, _742, _253.fa_layers_a.w, _744, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _644 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, raise);\n    out.gl_Position = _144.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "inst_name": "_144",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _196)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_196.fa_joint_rows[_187] * weights[i]);\n        r1 += (_196.fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196.fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _196 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _196);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _149);\n    vertex0(param_8, raise);\n    out.gl_Position = _149.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec2",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_149",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
