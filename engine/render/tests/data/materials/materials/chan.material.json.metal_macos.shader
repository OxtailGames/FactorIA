{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _144, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _144.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, vertex_color1, vertex_uv1, _144, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3((in.fa_attr_uv1 * _144.fa_lm_so.xy) + _144.fa_lm_so.zw, float(_144.fa_lm_so.x > 0.0));\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2582 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    bool _541 = _536.fa_cl_info.x < 0.0;\n    bool _548;\n    if (!_541)\n    {\n        _548 = _536.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = _536.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = _536.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = _536.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return float4(0.0);\n    }\n    float4 _580 = float4(world_pos, 1.0);\n    float _587 = dot(_536.fa_cl_vpw, _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _609 = float2(dot(_536.fa_cl_vpx, _580), dot(_536.fa_cl_vpy, _580)) / float2(_587);\n    int _613 = int(_536.fa_cl_grid.x);\n    int _617 = int(_536.fa_cl_grid.y);\n    int param = (int(_536.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_536.fa_cl_fwd.xyz, world_pos) + _536.fa_cl_fwd.w, _536.fa_cl_grid.w) / _536.fa_cl_grid.w) * _536.fa_cl_grid.z)), 0, int(_536.fa_cl_info.y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5) + 0.5) * _536.fa_cl_grid.y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5) + 0.5) * _536.fa_cl_grid.x)), 0, _613 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _536);\n    return int2(int(_693.x), int(_693.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_536.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3397 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _536);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3553 = fa_linear_to_srgb(param);\n        c = _3553;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3561 = fa_srgb_to_linear(param_1);\n            c = _3561;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _291;\n    if (bool(i.front_facing))\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    float3 _315 = fast::normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    float3 _343 = fast::normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    float3 _346;\n    if (bool(i.front_facing))\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _536, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _536.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3592 = fa_tex_fix(param_2, param_3);\n    float4 _4891 = base_t;\n    _4891.x = _3592.x;\n    _4891.y = _3592.y;\n    _4891.z = _3592.z;\n    base_t = _4891;\n    float4 _3606 = (_4891 * _536.fa_base_color) * i.vertex_color;\n    float3 _4758 = i.world_normal;\n    if (_536.fa_maps.z > 0.5)\n    {\n        float param_4 = _536.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3638 = fa_tex_fix(param_6, param_7);\n        float3 _3641 = (_3638 * 2.0) - float3(1.0);\n        float2 _3646 = _3641.xy * _536.fa_maps.x;\n        float3 _4899 = _3641;\n        _4899.x = _3646.x;\n        _4899.y = _3646.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4899;\n        _4758 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _536.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3675 = fa_tex_fix(param_12, param_13);\n    float4 _4902 = mrt;\n    _4902.x = _3675.x;\n    _4902.y = _3675.y;\n    _4902.z = _3675.z;\n    mrt = _4902;\n    float4 _3703 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _536.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3703.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3715 = fa_tex_fix(param_16, param_17);\n    float param_18 = _536.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3745 = fa_tex_fix(param_20, param_21);\n    float _4763 = _536.fa_layers_a.x;\n    float _4764 = _536.fa_layers_a.y;\n    float _4767 = _536.fa_layers_a.z;\n    float _4766 = _536.fa_layers_b.w;\n    float _4769 = _536.fa_layers_c.x;\n    if (_536.fa_layers_c.z > 0.5)\n    {\n        if (mod(_536.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4763 *= _3715.y;\n            _4764 *= _3715.z;\n            _4766 *= _3703.w;\n        }\n        if (_536.fa_layers_c.z > 1.5)\n        {\n            _4767 *= mrt.x;\n            _4769 *= mrt.w;\n        }\n    }\n    return Surface{ _3606.xyz, _3606.w, _4758, fast::clamp(_536.fa_pbr.x * _3675.z, 0.0, 1.0), fast::clamp(_536.fa_pbr.y * _3675.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_536.fa_maps.y * (_3715.x - 1.0)), _536.fa_emissive.xyz + (_536.fa_model_emissive.xyz * _3745), _4763, _4764, _536.fa_layers_b.xyz, _4766, _4767, _536.fa_layers_a.w, _4769, _536.fa_layers_c.y, _536.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _774 = rect.zw - rect.xy;\n    float2 _778 = _774 * atlas;\n    float2 _782 = ddx * _778;\n    float2 _786 = ddy * _778;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _774)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _821 = _536.fa_counts.y < 0.5;\n    bool _828;\n    if (!_821)\n    {\n        _828 = _536.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    float3 _834 = dfdx(world_pos);\n    float3 _837 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _841 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _536);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(_536.fa_counts.y + 0.5);\n    int param_1 = _855;\n    float4 _859 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    float4 _871 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _872 = _871.x;\n    int _878 = int(_536.fa_counts.w + 0.5) - 1;\n    int _882 = int(_841.z);\n    float3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        float4 _918 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_918.w + 0.5) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        float4 _933 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _913 + 1;\n        float4 _938 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _913 + 2;\n        float4 _943 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        float3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        float3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = fast::clamp(dot(geo_normal, fast::normalize(_960)) * _918.z, 0.0, 1.0);\n        if (_1001 <= 0.0)\n        {\n            continue;\n        }\n        float _1021 = (fast::clamp((0.5 - abs(_965)) * 10.0, 0.0, 1.0) * _1001) * _918.x;\n        float2 _1029 = float2(_951 + 0.5, 0.5 - _958);\n        float2 _1039 = float2(dot(_946, _834), dot(_953, _834));\n        float2 _1049 = float2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        float4 _1054 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _913 + 3;\n        float4 _1059 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _913 + 4;\n        float4 _1064 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            float4 param_11 = _1059;\n            float2 param_12 = _1029;\n            float2 param_13 = _862;\n            float2 param_14 = _1039;\n            float2 param_15 = _1049;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_872 > 0.5) && (_872 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1100 = fa_dc_to_linear(param_16);\n                float4 _4814 = tx;\n                _4814.x = _1100.x;\n                _4814.y = _1100.y;\n                _4814.z = _1100.z;\n                tx = _4814;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1021 * tex_a) * _1054.w, 0.0, 1.0)));\n        if (_1064.z > _1064.x)\n        {\n            float4 param_17 = _1064;\n            float2 param_18 = _1029;\n            float2 param_19 = _862;\n            float2 param_20 = _1039;\n            float2 param_21 = _1049;\n            float4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_872 > 1.5)\n            {\n                float3 param_22 = _1144.xyz;\n                float3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            float3 _1164 = (_1148 * 2.0) - float3(1.0);\n            float2 _1169 = _1164.xy * _918.y;\n            float3 _1191 = (fast::normalize(_946) * _1169.x) + (fast::normalize(_953) * _1169.y);\n            float3 _1194 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1194, fast::normalize((_1194 * fast::max(_1164.z, 0.0500000007450580596923828125)) + (_1191 - (_1194 * dot(_1194, _1191)))), float3(fast::clamp(_1021 * (_1074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2507 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2515 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return mix(mix(_2582[_2587], _2582[_2587 + 1], _2531), mix(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4681 = false;\n    float _4682 = 1.0;\n    float _4683 = 1.0;\n    float _4684 = 1.0;\n    float _4685 = 0.0;\n    float _4686 = 0.0;\n    float _4687 = 0.0;\n    float _4688 = 0.0;\n    float _4690 = 1.0;\n    bool _4691 = false;\n    float3 _4692 = float3(0.0);\n    float _4693 = 1.0;\n    float _4694 = 1.0;\n    float _4695 = 1.0;\n    float _4696 = 0.0;\n    float _4697 = 0.0;\n    float3 _4698 = float3(1.0, 0.0, 0.0);\n    float3 _4699 = float3(0.0, 0.0, 1.0);\n    float _4700 = 1.0;\n    float _4701 = 1.0;\n    float _2660 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2664 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2669 = (_2660 != 1.0) || (_2664 != 1.5);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0) / (_2664 + 1.0);\n        f0 = mix(fast::min(float3(_2687 * _2687) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2660, s.albedo, float3(metallic));\n        _4682 = mix(_2660, 1.0, metallic);\n        _4681 = true;\n    }\n    float _2715 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2715 > 0.0)\n    {\n        float _2723 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4685 = _2715;\n        _4686 = _2723;\n        float _2730 = _2723 * _2723;\n        _4687 = _2730;\n        _4688 = _2730 * _2730;\n        float _2742 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4690 = _2742;\n        _4683 = 1.0 - (_2715 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2742, 0.0, 1.0), 5.0))));\n        _4681 = true;\n    }\n    float3 _2762 = fast::max(s.sheen_color, float3(0.0));\n    float _2771 = fast::max(_2762.x, fast::max(_2762.y, _2762.z));\n    if (_2771 > 0.0)\n    {\n        float _2779 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4691 = true;\n        _4692 = _2762;\n        _4693 = _2779;\n        _4694 = _2779 * _2779;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4696 = _2796;\n        _4695 = 1.0 - fast::min(_2771 * _2796, 1.0);\n        _4681 = true;\n    }\n    _4684 = _4683 * _4695;\n    float _2815 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2815 != 0.0)\n    {\n        float3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2847 = t;\n        float3 _2848 = fast::normalize(_2847);\n        t = _2848;\n        float3 _2873 = fast::normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4698 = _2873;\n        _4699 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = mix(_2883, 1.0, _2815 * _2815);\n        bool _2891 = _2815 > 0.0;\n        _4700 = _2891 ? _2889 : _2883;\n        _4701 = _2891 ? _2883 : _2889;\n        _4697 = _2815;\n        _4681 = true;\n    }\n    return FaLayers{ short(_4681), _4682, _4683, _4684, _4685, _4686, _4687, _4688, i.world_normal, _4690, short(_4691), _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_536.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _536.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _536, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    int param = (int(_536.fa_cl_info.x) + int(_536.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _536);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _410 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _416 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _419 = _416.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _425 = _419 < 0.5;\n    float3 l;\n    if (_425)\n    {\n        l = fast::normalize(_410.xyz);\n    }\n    else\n    {\n        float3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / float3(fast::max(_439, 9.9999997473787516355514526367188e-05));\n        float _454 = _439 / fast::max(_410.w, 0.001000000047497451305389404296875);\n        float _460 = fast::clamp(1.0 - (_454 * _454), 0.0, 1.0);\n        atten = _460 * _460;\n        if (_419 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _474 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            float4 _490 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5)\n            {\n                cos_inner = mix(_484, 1.0, 0.25);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, fast::normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _416.xyz * atten, atten, 1.0, dist, _522 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1276)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = _1276.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = _1276.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = _1276.fa_shadow_split.z;\n            }\n            else\n            {\n                _1290 = _1276.fa_shadow_split.w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1327;\n    if (conv.x < 0.5)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1373 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1387 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            float2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            float2 param_6 = uv + (_1406 * _1276.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        float2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1481 * _1276.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1462);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    float _1523 = fast::max(_1276.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1528 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1534 = sqrt(1.0 - (_1528 * _1528));\n    float _1541 = fast::min(_1534 / fast::max(_1528, 0.20000000298023223876953125), 4.0);\n    float _1546;\n    if (_1276.fa_shadow_bias.y > 0.0)\n    {\n        _1546 = _1276.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1546 = 1.5 * _1276.fa_shadow_info[ci].x;\n    }\n    float4 _1571 = _1276.fa_shadow_mat[ci] * float4(world + (n * (_1546 * _1534)), 1.0);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < _1276.fa_shadow_rect[ci].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > _1276.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < _1276.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > _1276.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0;\n    }\n    float _1624;\n    if (_1276.fa_shadow_bias.x > 0.0)\n    {\n        _1624 = _1276.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1624 = 1.5 * _1276.fa_shadow_info[ci].x;\n    }\n    float2 param = _1571.xy;\n    float4 param_1 = _1276.fa_shadow_rect[ci];\n    float param_2 = _1571.z - ((_1624 * (1.0 + (0.5 * _1541))) / _1523);\n    float param_3 = _1276.fa_shadow_info[ci].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25;\n    float param_6 = ((_1276.fa_shadow_info[ci].x * fast::min(_1541, 3.0)) * 0.5) / _1523;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1276.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1276.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    if (_536.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2051 = int(_1276.fa_shadow_cfg.x + 0.5);\n    if (_2051 < 1)\n    {\n        return 1.0;\n    }\n    float _2066 = dot(world - _1276.fa_shadow_eye.xyz, _1276.fa_shadow_fwd.xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param, _1276))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > _1276.fa_shadow_split.x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > _1276.fa_shadow_split.y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > _1276.fa_shadow_split.z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n        s = _2133;\n        if (_2133 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1276.fa_shadow_cfg.y > 0.0)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5, _1276);\n        }\n        else\n        {\n            _2158 = _1276.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2177 = _1276.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1276) - _2158, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2188 = fast::clamp((_2066 - (fa_shadow_split_at(param_7, _1276) - _2177)) / _2177, 0.0, 1.0);\n        if (_2188 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n                s2 = _2209;\n                if (_2209 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    bool _1682 = _536.fa_pbr.z < 0.5;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = _1276.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0;\n    }\n    int param = (int(_1276.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1703 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1713 = int(_1704 + 0.5);\n    int param_1 = _1713;\n    float4 _1717 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1713 + 1;\n    float4 _1722 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0)\n    {\n        float _1742 = 1.0 - smoothstep(0.75 * _1725, _1725, length(world - _1276.fa_shadow_eye.xyz));\n        fade = _1742;\n        if (_1742 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1761 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    float4 _1824 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1810 + 4;\n    float4 _1829 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1810 + 5;\n    float4 _1834 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1846 = _1834.x * fast::max(dot(_1824, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1851 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1874 = fast::clamp(dot(n, _1824.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1897 = fast::min(sqrt(1.0 - (_1874 * _1874)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1824, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5 * _1846;\n    }\n    float4 _1922 = float4(world + (n * (_1902 * sqrt(1.0 - (_1851 * _1851)))), 1.0);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0;\n    }\n    float2 _1944 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1922), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1922)) / float2(_1926);\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5 * _1846;\n    }\n    float2 param_10 = _1944;\n    float4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0 + (0.5 * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0;\n    float param_15 = _1834.z * 0.25;\n    float param_16 = (_1846 * fast::min(_1897, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5);\n    float param_19 = _1717.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3424 = fa_lm.z > 0.5;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4743 = _3452.direction;\n    float3 _4738 = _3452.color;\n    float _4745 = _3452.attenuation;\n    float _4740 = _3452.shadow;\n    int _4748 = _3452.type;\n    if ((_4748 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4743;\n        float _3466 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex, fa_world_pos);\n        _4740 = _3466;\n        _4738 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4748 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4745 > 0.0;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4743;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex);\n            _4740 = _3495;\n            _4738 *= _3495;\n        }\n    }\n    return LightSample{ _4743, _4738, _4745, _4740, _3452._distance, _4748 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3057) * _3057);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3138 = 1.0 / alpha;\n    return ((2.0 + _3138) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3138)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3249) * _3249);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3170);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3170));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3322 = fast::max(dot(L.nc, l), 0.0);\n        float _3328 = fast::max(dot(L.nc, h), 0.0);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3337) * _3337)) * (0.5 / fast::max(mix((2.0 * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3322)) * _3322);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2439 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2442 = _2439.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2442 * _2442, exp2((-9.27999973297119140625) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_536.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _536.fa_env_horizon.w)).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625 * _2345;\n    return mix(mix(_536.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_536.fa_env_horizon.xyz, _536.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2345)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2375, 0.0500000007450580596923828125 + _2375, d.y))), ((_536.fa_env_sky.xyz + _536.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2345 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2924;\n        if (L.aniso >= 0.0)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2924, v), _2924), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _536, fa_env_smp, fa_env_tex) * ((f0 * _2957.x) + (float3(L.f90) * _2957.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _536, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3012 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _536, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2481 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _536, fa_env_smp, fa_env_tex) * ((f0 * _2481.x) + float3(_2481.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1276)\n{\n    if (_1276.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2233 = int(_1276.fa_shadow_cfg.x + 0.5);\n    float _2243 = dot(world - _1276.fa_shadow_eye.xyz, _1276.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param, _1276);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > _1276.fa_shadow_split.x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > _1276.fa_shadow_split.y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > _1276.fa_shadow_split.z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _536 [[buffer(1)]], constant fa_shadows& _1276 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4460 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4460 = -_4460;\n    }\n    float3 _3885 = fast::normalize(_536.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _536, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n    Surface _3893 = fa_standard_surface(param_1, _536, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4491 = _3893.albedo;\n    float _4492 = _3893.alpha;\n    float3 _4493 = _3893.normal;\n    float _4494 = _3893.metallic;\n    float _4495 = _3893.roughness;\n    float _4496 = _3893.occlusion;\n    float3 _4497 = _3893.emission;\n    float _4498 = _3893.clearcoat;\n    float _4499 = _3893.clearcoat_roughness;\n    float3 _4500 = _3893.sheen_color;\n    float _4501 = _3893.sheen_roughness;\n    float _4502 = _3893.anisotropy;\n    float _4503 = _3893.anisotropy_rotation;\n    float _4504 = _3893.specular;\n    float _4505 = _3893.ior;\n    float3 _4506 = _3893.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n    Surface param_3 = _3893;\n    surface(param_2, param_3);\n    _4491 = param_3.albedo;\n    _4492 = param_3.alpha;\n    _4493 = param_3.normal;\n    _4494 = param_3.metallic;\n    _4495 = param_3.roughness;\n    _4496 = param_3.occlusion;\n    _4497 = param_3.emission;\n    _4498 = param_3.clearcoat;\n    _4499 = param_3.clearcoat_roughness;\n    _4500 = param_3.sheen_color;\n    _4501 = param_3.sheen_roughness;\n    _4502 = param_3.anisotropy;\n    _4503 = param_3.anisotropy_rotation;\n    _4504 = param_3.specular;\n    _4505 = param_3.ior;\n    _4506 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4460;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _536, fa_decal_tex, fa_env_smp);\n    _4491 = param_6;\n    _4493 = param_7;\n    float3 result;\n    if (_536.fa_emissive.w > 0.5)\n    {\n        result = _4491;\n    }\n    else\n    {\n        float3 _3932 = fast::normalize(_4493);\n        float _3939 = fast::clamp(_4494, 0.0, 1.0);\n        float _3943 = fast::clamp(_4495, 0.0500000007450580596923828125, 1.0);\n        float _3947 = _3943 * _3943;\n        float _3951 = _3947 * _3947;\n        float _3956 = fast::max(dot(_3932, _3885), 9.9999997473787516355514526367188e-05);\n        float3 _3962 = _4491 * (1.0 - _3939);\n        float3 _3969 = mix(float3(0.039999999105930328369140625), _4491, float3(_3939));\n        float3 f0 = _3969;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506 };\n        float3 param_10 = _3932;\n        float3 param_11 = _3885;\n        float param_12 = _3939;\n        float param_13 = _3943;\n        float3 param_14 = _3969;\n        FaLayers _3985 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3932;\n        float3 lit = (fa_indirect_diffuse(param_15, _536, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3962) * _4496;\n        if (_3985.on)\n        {\n            lit *= _3985.base_scale;\n        }\n        int _4007 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4007; ln++)\n        {\n            int param_16 = ln;\n            int _4020 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _536, fa_cl_ndir, fa_cl_slot);\n            bool _4023 = in.fa_lm.z > 0.5;\n            bool _4029;\n            if (_4023)\n            {\n                int param_17 = _4020;\n                _4029 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4029 = _4023;\n            }\n            if (_4029)\n            {\n                continue;\n            }\n            int param_18 = _4020;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4460;\n            LightSample _4041 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4665 = _4041.direction;\n            float _4049 = fast::max(dot(_3932, _4665), 0.0);\n            float _4055 = _4041.attenuation * _4041.shadow;\n            float3 _4060 = fast::normalize(_4665 + _3885);\n            float _4065 = fast::max(dot(_3932, _4060), 0.0);\n            float _4070 = fast::max(dot(_3885, _4060), 0.0);\n            if (_3985.on)\n            {\n                FaLayers param_21 = _3985;\n                float3 param_22 = _3962;\n                float3 param_23 = f0;\n                float3 param_24 = _3932;\n                float3 param_25 = _3885;\n                float3 param_26 = _4665;\n                float3 param_27 = _4060;\n                float param_28 = _4049;\n                float param_29 = _3956;\n                float param_30 = _4065;\n                float param_31 = _4070;\n                float param_32 = _3947;\n                float param_33 = _3951;\n                int param_34 = _4020;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4055));\n            }\n            else\n            {\n                float _4118 = ((_4065 * _4065) * (_3951 - 1.0)) + 1.0;\n                int param_35 = _4020;\n                lit += (((_3962 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4070, 5.0))) * (((_3951 / ((3.1415927410125732421875 * _4118) * _4118)) * (0.5 / fast::max(mix((2.0 * _4049) * _3956, _4049 + _3956, _3947), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4049))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4049 * _4055));\n            }\n        }\n        if (_3985.on)\n        {\n            FaLayers param_36 = _3985;\n            float3 param_37 = _3932;\n            float3 param_38 = _3885;\n            float3 param_39 = f0;\n            float param_40 = _3943;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _536, fa_env_smp, fa_env_tex) * _4496);\n        }\n        else\n        {\n            float3 param_41 = _3932;\n            float3 param_42 = _3885;\n            float3 param_43 = f0;\n            float param_44 = _3943;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _536, fa_env_smp, fa_env_tex) * _4496);\n        }\n        result = lit;\n    }\n    float3 _4211 = result;\n    float3 _4212 = _4211 + _4497;\n    result = _4212;\n    float3 param_45 = _4212;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1276);\n    bool _4221 = _536.fa_fog.w > 0.0;\n    bool _4228;\n    if (!_4221)\n    {\n        _4228 = _536.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4228 = _4221;\n    }\n    if (_4228)\n    {\n        float3 _4237 = in.fa_world_pos - _536.fa_camera_pos.xyz;\n        float _4243 = dot(_4237, _536.fa_fog_c.xyz);\n        bool _4247 = _536.fa_fog_c.w > 0.5;\n        float _4248;\n        if (_4247)\n        {\n            _4248 = _4243;\n        }\n        else\n        {\n            _4248 = length(_4237);\n        }\n        float _4260 = _4248 - _536.fa_fog_b.x;\n        if (_4260 > 0.0)\n        {\n            float _4269 = _536.fa_fog.w * _4260;\n            float tau = _4269 * _4269;\n            if (_536.fa_fog_b.y > 0.0)\n            {\n                float _4285;\n                if (_4247)\n                {\n                    _4285 = in.fa_world_pos.y - (_536.fa_fog_c.y * _4243);\n                }\n                else\n                {\n                    _4285 = _536.fa_camera_pos.y;\n                }\n                float _4306 = mix(_4285, in.fa_world_pos.y, fast::clamp(_536.fa_fog_b.x / _4248, 0.0, 1.0));\n                float _4310 = in.fa_world_pos.y - _4306;\n                float _4315 = _4306 - _536.fa_fog_b.z;\n                float _4320 = in.fa_world_pos.y - _536.fa_fog_b.z;\n                bool _4323 = _4315 <= 0.0;\n                bool _4324 = !_4323;\n                bool _4330;\n                if (_4324)\n                {\n                    _4330 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4330 = _4323;\n                }\n                float _4331;\n                if (_4330)\n                {\n                    _4331 = _536.fa_fog_b.y;\n                }\n                else\n                {\n                    _4331 = _536.fa_fog_b.y * exp(-fast::min(_536.fa_fog_b.w * _4315, 80.0));\n                }\n                bool _4358;\n                if (_4324)\n                {\n                    _4358 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4358 = _4323;\n                }\n                float _4359;\n                if (_4358)\n                {\n                    _4359 = _536.fa_fog_b.y * _4315;\n                }\n                else\n                {\n                    _4359 = (_536.fa_fog_b.y * (1.0 - exp(-fast::min(_536.fa_fog_b.w * _4315, 80.0)))) / _536.fa_fog_b.w;\n                }\n                bool _4384 = _4320 <= 0.0;\n                bool _4391;\n                if (!_4384)\n                {\n                    _4391 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4391 = _4384;\n                }\n                float _4392;\n                if (_4391)\n                {\n                    _4392 = _536.fa_fog_b.y * _4320;\n                }\n                else\n                {\n                    _4392 = (_536.fa_fog_b.y * (1.0 - exp(-fast::min(_536.fa_fog_b.w * _4320, 80.0)))) / _536.fa_fog_b.w;\n                }\n                float _4419;\n                if (abs(_4310) < 0.001000000047497451305389404296875)\n                {\n                    _4419 = _4331;\n                }\n                else\n                {\n                    _4419 = (_4392 - _4359) / _4310;\n                }\n                tau += (_4260 * fast::max(_4419, 0.0));\n            }\n            result = mix(result, _536.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4492);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1276",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _195)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_195.fa_joint_rows[_186] * weights[i]);\n        r1 += (_195.fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195.fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _149, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _149.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _195 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _195);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, vertex_color1, vertex_uv1, _149, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2582 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    bool _541 = _536.fa_cl_info.x < 0.0;\n    bool _548;\n    if (!_541)\n    {\n        _548 = _536.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = _536.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = _536.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = _536.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return float4(0.0);\n    }\n    float4 _580 = float4(world_pos, 1.0);\n    float _587 = dot(_536.fa_cl_vpw, _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _609 = float2(dot(_536.fa_cl_vpx, _580), dot(_536.fa_cl_vpy, _580)) / float2(_587);\n    int _613 = int(_536.fa_cl_grid.x);\n    int _617 = int(_536.fa_cl_grid.y);\n    int param = (int(_536.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_536.fa_cl_fwd.xyz, world_pos) + _536.fa_cl_fwd.w, _536.fa_cl_grid.w) / _536.fa_cl_grid.w) * _536.fa_cl_grid.z)), 0, int(_536.fa_cl_info.y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5) + 0.5) * _536.fa_cl_grid.y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5) + 0.5) * _536.fa_cl_grid.x)), 0, _613 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _536);\n    return int2(int(_693.x), int(_693.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_536.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3397 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _536);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3553 = fa_linear_to_srgb(param);\n        c = _3553;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3561 = fa_srgb_to_linear(param_1);\n            c = _3561;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _291;\n    if (bool(i.front_facing))\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    float3 _315 = fast::normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    float3 _343 = fast::normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    float3 _346;\n    if (bool(i.front_facing))\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _536, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _536.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3592 = fa_tex_fix(param_2, param_3);\n    float4 _4891 = base_t;\n    _4891.x = _3592.x;\n    _4891.y = _3592.y;\n    _4891.z = _3592.z;\n    base_t = _4891;\n    float4 _3606 = (_4891 * _536.fa_base_color) * i.vertex_color;\n    float3 _4758 = i.world_normal;\n    if (_536.fa_maps.z > 0.5)\n    {\n        float param_4 = _536.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3638 = fa_tex_fix(param_6, param_7);\n        float3 _3641 = (_3638 * 2.0) - float3(1.0);\n        float2 _3646 = _3641.xy * _536.fa_maps.x;\n        float3 _4899 = _3641;\n        _4899.x = _3646.x;\n        _4899.y = _3646.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4899;\n        _4758 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _536.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3675 = fa_tex_fix(param_12, param_13);\n    float4 _4902 = mrt;\n    _4902.x = _3675.x;\n    _4902.y = _3675.y;\n    _4902.z = _3675.z;\n    mrt = _4902;\n    float4 _3703 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _536.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3703.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3715 = fa_tex_fix(param_16, param_17);\n    float param_18 = _536.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3745 = fa_tex_fix(param_20, param_21);\n    float _4763 = _536.fa_layers_a.x;\n    float _4764 = _536.fa_layers_a.y;\n    float _4767 = _536.fa_layers_a.z;\n    float _4766 = _536.fa_layers_b.w;\n    float _4769 = _536.fa_layers_c.x;\n    if (_536.fa_layers_c.z > 0.5)\n    {\n        if (mod(_536.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4763 *= _3715.y;\n            _4764 *= _3715.z;\n            _4766 *= _3703.w;\n        }\n        if (_536.fa_layers_c.z > 1.5)\n        {\n            _4767 *= mrt.x;\n            _4769 *= mrt.w;\n        }\n    }\n    return Surface{ _3606.xyz, _3606.w, _4758, fast::clamp(_536.fa_pbr.x * _3675.z, 0.0, 1.0), fast::clamp(_536.fa_pbr.y * _3675.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_536.fa_maps.y * (_3715.x - 1.0)), _536.fa_emissive.xyz + (_536.fa_model_emissive.xyz * _3745), _4763, _4764, _536.fa_layers_b.xyz, _4766, _4767, _536.fa_layers_a.w, _4769, _536.fa_layers_c.y, _536.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _774 = rect.zw - rect.xy;\n    float2 _778 = _774 * atlas;\n    float2 _782 = ddx * _778;\n    float2 _786 = ddy * _778;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _774)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _821 = _536.fa_counts.y < 0.5;\n    bool _828;\n    if (!_821)\n    {\n        _828 = _536.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    float3 _834 = dfdx(world_pos);\n    float3 _837 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _841 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _536);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(_536.fa_counts.y + 0.5);\n    int param_1 = _855;\n    float4 _859 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    float4 _871 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _872 = _871.x;\n    int _878 = int(_536.fa_counts.w + 0.5) - 1;\n    int _882 = int(_841.z);\n    float3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        float4 _918 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_918.w + 0.5) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        float4 _933 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _913 + 1;\n        float4 _938 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _913 + 2;\n        float4 _943 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        float3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        float3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = fast::clamp(dot(geo_normal, fast::normalize(_960)) * _918.z, 0.0, 1.0);\n        if (_1001 <= 0.0)\n        {\n            continue;\n        }\n        float _1021 = (fast::clamp((0.5 - abs(_965)) * 10.0, 0.0, 1.0) * _1001) * _918.x;\n        float2 _1029 = float2(_951 + 0.5, 0.5 - _958);\n        float2 _1039 = float2(dot(_946, _834), dot(_953, _834));\n        float2 _1049 = float2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        float4 _1054 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _913 + 3;\n        float4 _1059 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _913 + 4;\n        float4 _1064 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            float4 param_11 = _1059;\n            float2 param_12 = _1029;\n            float2 param_13 = _862;\n            float2 param_14 = _1039;\n            float2 param_15 = _1049;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_872 > 0.5) && (_872 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1100 = fa_dc_to_linear(param_16);\n                float4 _4814 = tx;\n                _4814.x = _1100.x;\n                _4814.y = _1100.y;\n                _4814.z = _1100.z;\n                tx = _4814;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1021 * tex_a) * _1054.w, 0.0, 1.0)));\n        if (_1064.z > _1064.x)\n        {\n            float4 param_17 = _1064;\n            float2 param_18 = _1029;\n            float2 param_19 = _862;\n            float2 param_20 = _1039;\n            float2 param_21 = _1049;\n            float4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_872 > 1.5)\n            {\n                float3 param_22 = _1144.xyz;\n                float3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            float3 _1164 = (_1148 * 2.0) - float3(1.0);\n            float2 _1169 = _1164.xy * _918.y;\n            float3 _1191 = (fast::normalize(_946) * _1169.x) + (fast::normalize(_953) * _1169.y);\n            float3 _1194 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1194, fast::normalize((_1194 * fast::max(_1164.z, 0.0500000007450580596923828125)) + (_1191 - (_1194 * dot(_1194, _1191)))), float3(fast::clamp(_1021 * (_1074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2507 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2515 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return mix(mix(_2582[_2587], _2582[_2587 + 1], _2531), mix(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4681 = false;\n    float _4682 = 1.0;\n    float _4683 = 1.0;\n    float _4684 = 1.0;\n    float _4685 = 0.0;\n    float _4686 = 0.0;\n    float _4687 = 0.0;\n    float _4688 = 0.0;\n    float _4690 = 1.0;\n    bool _4691 = false;\n    float3 _4692 = float3(0.0);\n    float _4693 = 1.0;\n    float _4694 = 1.0;\n    float _4695 = 1.0;\n    float _4696 = 0.0;\n    float _4697 = 0.0;\n    float3 _4698 = float3(1.0, 0.0, 0.0);\n    float3 _4699 = float3(0.0, 0.0, 1.0);\n    float _4700 = 1.0;\n    float _4701 = 1.0;\n    float _2660 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2664 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2669 = (_2660 != 1.0) || (_2664 != 1.5);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0) / (_2664 + 1.0);\n        f0 = mix(fast::min(float3(_2687 * _2687) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2660, s.albedo, float3(metallic));\n        _4682 = mix(_2660, 1.0, metallic);\n        _4681 = true;\n    }\n    float _2715 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2715 > 0.0)\n    {\n        float _2723 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4685 = _2715;\n        _4686 = _2723;\n        float _2730 = _2723 * _2723;\n        _4687 = _2730;\n        _4688 = _2730 * _2730;\n        float _2742 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4690 = _2742;\n        _4683 = 1.0 - (_2715 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2742, 0.0, 1.0), 5.0))));\n        _4681 = true;\n    }\n    float3 _2762 = fast::max(s.sheen_color, float3(0.0));\n    float _2771 = fast::max(_2762.x, fast::max(_2762.y, _2762.z));\n    if (_2771 > 0.0)\n    {\n        float _2779 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4691 = true;\n        _4692 = _2762;\n        _4693 = _2779;\n        _4694 = _2779 * _2779;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4696 = _2796;\n        _4695 = 1.0 - fast::min(_2771 * _2796, 1.0);\n        _4681 = true;\n    }\n    _4684 = _4683 * _4695;\n    float _2815 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2815 != 0.0)\n    {\n        float3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2847 = t;\n        float3 _2848 = fast::normalize(_2847);\n        t = _2848;\n        float3 _2873 = fast::normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4698 = _2873;\n        _4699 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = mix(_2883, 1.0, _2815 * _2815);\n        bool _2891 = _2815 > 0.0;\n        _4700 = _2891 ? _2889 : _2883;\n        _4701 = _2891 ? _2883 : _2889;\n        _4697 = _2815;\n        _4681 = true;\n    }\n    return FaLayers{ short(_4681), _4682, _4683, _4684, _4685, _4686, _4687, _4688, i.world_normal, _4690, short(_4691), _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_536.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _536.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _536, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536)\n{\n    int param = (int(_536.fa_cl_info.x) + int(_536.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _536);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _410 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _416 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _419 = _416.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _425 = _419 < 0.5;\n    float3 l;\n    if (_425)\n    {\n        l = fast::normalize(_410.xyz);\n    }\n    else\n    {\n        float3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / float3(fast::max(_439, 9.9999997473787516355514526367188e-05));\n        float _454 = _439 / fast::max(_410.w, 0.001000000047497451305389404296875);\n        float _460 = fast::clamp(1.0 - (_454 * _454), 0.0, 1.0);\n        atten = _460 * _460;\n        if (_419 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _474 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            float4 _490 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5)\n            {\n                cos_inner = mix(_484, 1.0, 0.25);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, fast::normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _416.xyz * atten, atten, 1.0, dist, _522 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1276)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = _1276.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = _1276.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = _1276.fa_shadow_split.z;\n            }\n            else\n            {\n                _1290 = _1276.fa_shadow_split.w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1327;\n    if (conv.x < 0.5)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1373 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1387 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            float2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            float2 param_6 = uv + (_1406 * _1276.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        float2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1481 * _1276.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1462);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    float _1523 = fast::max(_1276.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1528 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1534 = sqrt(1.0 - (_1528 * _1528));\n    float _1541 = fast::min(_1534 / fast::max(_1528, 0.20000000298023223876953125), 4.0);\n    float _1546;\n    if (_1276.fa_shadow_bias.y > 0.0)\n    {\n        _1546 = _1276.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1546 = 1.5 * _1276.fa_shadow_info[ci].x;\n    }\n    float4 _1571 = _1276.fa_shadow_mat[ci] * float4(world + (n * (_1546 * _1534)), 1.0);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < _1276.fa_shadow_rect[ci].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > _1276.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < _1276.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > _1276.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0;\n    }\n    float _1624;\n    if (_1276.fa_shadow_bias.x > 0.0)\n    {\n        _1624 = _1276.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1624 = 1.5 * _1276.fa_shadow_info[ci].x;\n    }\n    float2 param = _1571.xy;\n    float4 param_1 = _1276.fa_shadow_rect[ci];\n    float param_2 = _1571.z - ((_1624 * (1.0 + (0.5 * _1541))) / _1523);\n    float param_3 = _1276.fa_shadow_info[ci].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25;\n    float param_6 = ((_1276.fa_shadow_info[ci].x * fast::min(_1541, 3.0)) * 0.5) / _1523;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1276.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1276.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    if (_536.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2051 = int(_1276.fa_shadow_cfg.x + 0.5);\n    if (_2051 < 1)\n    {\n        return 1.0;\n    }\n    float _2066 = dot(world - _1276.fa_shadow_eye.xyz, _1276.fa_shadow_fwd.xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param, _1276))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > _1276.fa_shadow_split.x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > _1276.fa_shadow_split.y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > _1276.fa_shadow_split.z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n        s = _2133;\n        if (_2133 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1276.fa_shadow_cfg.y > 0.0)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5, _1276);\n        }\n        else\n        {\n            _2158 = _1276.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2177 = _1276.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1276) - _2158, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2188 = fast::clamp((_2066 - (fa_shadow_split_at(param_7, _1276) - _2177)) / _2177, 0.0, 1.0);\n        if (_2188 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex);\n                s2 = _2209;\n                if (_2209 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex)\n{\n    bool _1682 = _536.fa_pbr.z < 0.5;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = _1276.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0;\n    }\n    int param = (int(_1276.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1703 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1713 = int(_1704 + 0.5);\n    int param_1 = _1713;\n    float4 _1717 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1713 + 1;\n    float4 _1722 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0)\n    {\n        float _1742 = 1.0 - smoothstep(0.75 * _1725, _1725, length(world - _1276.fa_shadow_eye.xyz));\n        fade = _1742;\n        if (_1742 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1761 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    float4 _1824 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1810 + 4;\n    float4 _1829 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1810 + 5;\n    float4 _1834 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1846 = _1834.x * fast::max(dot(_1824, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1851 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1874 = fast::clamp(dot(n, _1824.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1897 = fast::min(sqrt(1.0 - (_1874 * _1874)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1824, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5 * _1846;\n    }\n    float4 _1922 = float4(world + (n * (_1902 * sqrt(1.0 - (_1851 * _1851)))), 1.0);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0;\n    }\n    float2 _1944 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1922), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1922)) / float2(_1926);\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5 * _1846;\n    }\n    float2 param_10 = _1944;\n    float4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0 + (0.5 * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0;\n    float param_15 = _1834.z * 0.25;\n    float param_16 = (_1846 * fast::min(_1897, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5);\n    float param_19 = _1717.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1276, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _536, thread float4& gl_FragCoord, constant fa_shadows& _1276, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3424 = fa_lm.z > 0.5;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4743 = _3452.direction;\n    float3 _4738 = _3452.color;\n    float _4745 = _3452.attenuation;\n    float _4740 = _3452.shadow;\n    int _4748 = _3452.type;\n    if ((_4748 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4743;\n        float _3466 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex, fa_world_pos);\n        _4740 = _3466;\n        _4738 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4748 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4745 > 0.0;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4743;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex);\n            _4740 = _3495;\n            _4738 *= _3495;\n        }\n    }\n    return LightSample{ _4743, _4738, _4745, _4740, _3452._distance, _4748 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3057) * _3057);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3138 = 1.0 / alpha;\n    return ((2.0 + _3138) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3138)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3249) * _3249);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3170);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3170));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3322 = fast::max(dot(L.nc, l), 0.0);\n        float _3328 = fast::max(dot(L.nc, h), 0.0);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3337) * _3337)) * (0.5 / fast::max(mix((2.0 * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3322)) * _3322);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2439 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2442 = _2439.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2442 * _2442, exp2((-9.27999973297119140625) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_536.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _536.fa_env_horizon.w)).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625 * _2345;\n    return mix(mix(_536.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_536.fa_env_horizon.xyz, _536.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2345)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2375, 0.0500000007450580596923828125 + _2375, d.y))), ((_536.fa_env_sky.xyz + _536.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2345 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2924;\n        if (L.aniso >= 0.0)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2924, v), _2924), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _536, fa_env_smp, fa_env_tex) * ((f0 * _2957.x) + (float3(L.f90) * _2957.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _536, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3012 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _536, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _536, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2481 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _536, fa_env_smp, fa_env_tex) * ((f0 * _2481.x) + float3(_2481.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1276)\n{\n    if (_1276.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2233 = int(_1276.fa_shadow_cfg.x + 0.5);\n    float _2243 = dot(world - _1276.fa_shadow_eye.xyz, _1276.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param, _1276);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > _1276.fa_shadow_split.x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > _1276.fa_shadow_split.y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > _1276.fa_shadow_split.z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _536 [[buffer(1)]], constant fa_shadows& _1276 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4460 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4460 = -_4460;\n    }\n    float3 _3885 = fast::normalize(_536.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _536, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n    Surface _3893 = fa_standard_surface(param_1, _536, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4491 = _3893.albedo;\n    float _4492 = _3893.alpha;\n    float3 _4493 = _3893.normal;\n    float _4494 = _3893.metallic;\n    float _4495 = _3893.roughness;\n    float _4496 = _3893.occlusion;\n    float3 _4497 = _3893.emission;\n    float _4498 = _3893.clearcoat;\n    float _4499 = _3893.clearcoat_roughness;\n    float3 _4500 = _3893.sheen_color;\n    float _4501 = _3893.sheen_roughness;\n    float _4502 = _3893.anisotropy;\n    float _4503 = _3893.anisotropy_rotation;\n    float _4504 = _3893.specular;\n    float _4505 = _3893.ior;\n    float3 _4506 = _3893.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n    Surface param_3 = _3893;\n    surface(param_2, param_3);\n    _4491 = param_3.albedo;\n    _4492 = param_3.alpha;\n    _4493 = param_3.normal;\n    _4494 = param_3.metallic;\n    _4495 = param_3.roughness;\n    _4496 = param_3.occlusion;\n    _4497 = param_3.emission;\n    _4498 = param_3.clearcoat;\n    _4499 = param_3.clearcoat_roughness;\n    _4500 = param_3.sheen_color;\n    _4501 = param_3.sheen_roughness;\n    _4502 = param_3.anisotropy;\n    _4503 = param_3.anisotropy_rotation;\n    _4504 = param_3.specular;\n    _4505 = param_3.ior;\n    _4506 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4460;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _536, fa_decal_tex, fa_env_smp);\n    _4491 = param_6;\n    _4493 = param_7;\n    float3 result;\n    if (_536.fa_emissive.w > 0.5)\n    {\n        result = _4491;\n    }\n    else\n    {\n        float3 _3932 = fast::normalize(_4493);\n        float _3939 = fast::clamp(_4494, 0.0, 1.0);\n        float _3943 = fast::clamp(_4495, 0.0500000007450580596923828125, 1.0);\n        float _3947 = _3943 * _3943;\n        float _3951 = _3947 * _3947;\n        float _3956 = fast::max(dot(_3932, _3885), 9.9999997473787516355514526367188e-05);\n        float3 _3962 = _4491 * (1.0 - _3939);\n        float3 _3969 = mix(float3(0.039999999105930328369140625), _4491, float3(_3939));\n        float3 f0 = _3969;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4460, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3885, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506 };\n        float3 param_10 = _3932;\n        float3 param_11 = _3885;\n        float param_12 = _3939;\n        float param_13 = _3943;\n        float3 param_14 = _3969;\n        FaLayers _3985 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3932;\n        float3 lit = (fa_indirect_diffuse(param_15, _536, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3962) * _4496;\n        if (_3985.on)\n        {\n            lit *= _3985.base_scale;\n        }\n        int _4007 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4007; ln++)\n        {\n            int param_16 = ln;\n            int _4020 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _536, fa_cl_ndir, fa_cl_slot);\n            bool _4023 = in.fa_lm.z > 0.5;\n            bool _4029;\n            if (_4023)\n            {\n                int param_17 = _4020;\n                _4029 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4029 = _4023;\n            }\n            if (_4029)\n            {\n                continue;\n            }\n            int param_18 = _4020;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4460;\n            LightSample _4041 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _536, gl_FragCoord, _1276, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4665 = _4041.direction;\n            float _4049 = fast::max(dot(_3932, _4665), 0.0);\n            float _4055 = _4041.attenuation * _4041.shadow;\n            float3 _4060 = fast::normalize(_4665 + _3885);\n            float _4065 = fast::max(dot(_3932, _4060), 0.0);\n            float _4070 = fast::max(dot(_3885, _4060), 0.0);\n            if (_3985.on)\n            {\n                FaLayers param_21 = _3985;\n                float3 param_22 = _3962;\n                float3 param_23 = f0;\n                float3 param_24 = _3932;\n                float3 param_25 = _3885;\n                float3 param_26 = _4665;\n                float3 param_27 = _4060;\n                float param_28 = _4049;\n                float param_29 = _3956;\n                float param_30 = _4065;\n                float param_31 = _4070;\n                float param_32 = _3947;\n                float param_33 = _3951;\n                int param_34 = _4020;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4055));\n            }\n            else\n            {\n                float _4118 = ((_4065 * _4065) * (_3951 - 1.0)) + 1.0;\n                int param_35 = _4020;\n                lit += (((_3962 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4070, 5.0))) * (((_3951 / ((3.1415927410125732421875 * _4118) * _4118)) * (0.5 / fast::max(mix((2.0 * _4049) * _3956, _4049 + _3956, _3947), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4049))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4049 * _4055));\n            }\n        }\n        if (_3985.on)\n        {\n            FaLayers param_36 = _3985;\n            float3 param_37 = _3932;\n            float3 param_38 = _3885;\n            float3 param_39 = f0;\n            float param_40 = _3943;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _536, fa_env_smp, fa_env_tex) * _4496);\n        }\n        else\n        {\n            float3 param_41 = _3932;\n            float3 param_42 = _3885;\n            float3 param_43 = f0;\n            float param_44 = _3943;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _536, fa_env_smp, fa_env_tex) * _4496);\n        }\n        result = lit;\n    }\n    float3 _4211 = result;\n    float3 _4212 = _4211 + _4497;\n    result = _4212;\n    float3 param_45 = _4212;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1276);\n    bool _4221 = _536.fa_fog.w > 0.0;\n    bool _4228;\n    if (!_4221)\n    {\n        _4228 = _536.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4228 = _4221;\n    }\n    if (_4228)\n    {\n        float3 _4237 = in.fa_world_pos - _536.fa_camera_pos.xyz;\n        float _4243 = dot(_4237, _536.fa_fog_c.xyz);\n        bool _4247 = _536.fa_fog_c.w > 0.5;\n        float _4248;\n        if (_4247)\n        {\n            _4248 = _4243;\n        }\n        else\n        {\n            _4248 = length(_4237);\n        }\n        float _4260 = _4248 - _536.fa_fog_b.x;\n        if (_4260 > 0.0)\n        {\n            float _4269 = _536.fa_fog.w * _4260;\n            float tau = _4269 * _4269;\n            if (_536.fa_fog_b.y > 0.0)\n            {\n                float _4285;\n                if (_4247)\n                {\n                    _4285 = in.fa_world_pos.y - (_536.fa_fog_c.y * _4243);\n                }\n                else\n                {\n                    _4285 = _536.fa_camera_pos.y;\n                }\n                float _4306 = mix(_4285, in.fa_world_pos.y, fast::clamp(_536.fa_fog_b.x / _4248, 0.0, 1.0));\n                float _4310 = in.fa_world_pos.y - _4306;\n                float _4315 = _4306 - _536.fa_fog_b.z;\n                float _4320 = in.fa_world_pos.y - _536.fa_fog_b.z;\n                bool _4323 = _4315 <= 0.0;\n                bool _4324 = !_4323;\n                bool _4330;\n                if (_4324)\n                {\n                    _4330 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4330 = _4323;\n                }\n                float _4331;\n                if (_4330)\n                {\n                    _4331 = _536.fa_fog_b.y;\n                }\n                else\n                {\n                    _4331 = _536.fa_fog_b.y * exp(-fast::min(_536.fa_fog_b.w * _4315, 80.0));\n                }\n                bool _4358;\n                if (_4324)\n                {\n                    _4358 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4358 = _4323;\n                }\n                float _4359;\n                if (_4358)\n                {\n                    _4359 = _536.fa_fog_b.y * _4315;\n                }\n                else\n                {\n                    _4359 = (_536.fa_fog_b.y * (1.0 - exp(-fast::min(_536.fa_fog_b.w * _4315, 80.0)))) / _536.fa_fog_b.w;\n                }\n                bool _4384 = _4320 <= 0.0;\n                bool _4391;\n                if (!_4384)\n                {\n                    _4391 = _536.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4391 = _4384;\n                }\n                float _4392;\n                if (_4391)\n                {\n                    _4392 = _536.fa_fog_b.y * _4320;\n                }\n                else\n                {\n                    _4392 = (_536.fa_fog_b.y * (1.0 - exp(-fast::min(_536.fa_fog_b.w * _4320, 80.0)))) / _536.fa_fog_b.w;\n                }\n                float _4419;\n                if (abs(_4310) < 0.001000000047497451305389404296875)\n                {\n                    _4419 = _4331;\n                }\n                else\n                {\n                    _4419 = (_4392 - _4359) / _4310;\n                }\n                tau += (_4260 * fast::max(_4419, 0.0));\n            }\n            result = mix(result, _536.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4492);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_195",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1276",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _144, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    float4 _187 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_144.fa_light_vp * _187).z;\n    fa_pre_r0 = float3(_144.fa_light_vp[0].x, _144.fa_light_vp[1].x, _144.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144.fa_light_vp[0].y, _144.fa_light_vp[1].y, _144.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144.fa_light_vp[0].z, _144.fa_light_vp[1].z, _144.fa_light_vp[2].z);\n    gl_Position = _144.fa_view_proj * _187;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, vertex_color1, vertex_uv1, _144, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _226, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _226.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _238.x;\n    _745.y = _238.y;\n    _745.z = _238.z;\n    base_t = _745;\n    float4 _253 = (_745 * _226.fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_226.fa_maps.z > 0.5)\n    {\n        float param_4 = _226.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _226.fa_maps.x;\n        float3 _753 = _290;\n        _753.x = _295.x;\n        _753.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _226.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _324.x;\n    _756.y = _324.y;\n    _756.z = _324.z;\n    mrt = _756;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _226.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _713 = _226.fa_layers_a.x;\n    float _714 = _226.fa_layers_a.y;\n    float _717 = _226.fa_layers_a.z;\n    float _716 = _226.fa_layers_b.w;\n    float _719 = _226.fa_layers_c.x;\n    if (_226.fa_layers_c.z > 0.5)\n    {\n        if (mod(_226.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _713 *= _366.y;\n            _714 *= _366.z;\n            _716 *= _354.w;\n        }\n        if (_226.fa_layers_c.z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _708, fast::clamp(_226.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_226.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_226.fa_maps.y * (_366.x - 1.0)), _226.fa_emissive.xyz + (_226.fa_model_emissive.xyz * _396), _713, _714, _226.fa_layers_b.xyz, _716, _717, _226.fa_layers_a.w, _719, _226.fa_layers_c.y, _226.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _226 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _619 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _530 = fast::normalize(_226.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _226, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _545 = fast::normalize(param_2.normal);\n    float3 _560 = fast::normalize(float3(dot(in.fa_pre_r0, _545), dot(in.fa_pre_r1, _545), dot(in.fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / float2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _195)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_195.fa_joint_rows[_186] * weights[i]);\n        r1 += (_195.fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195.fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _149, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    float4 _300 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_149.fa_light_vp * _300).z;\n    fa_pre_r0 = float3(_149.fa_light_vp[0].x, _149.fa_light_vp[1].x, _149.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149.fa_light_vp[0].y, _149.fa_light_vp[1].y, _149.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149.fa_light_vp[0].z, _149.fa_light_vp[1].z, _149.fa_light_vp[2].z);\n    gl_Position = _149.fa_view_proj * _300;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _195 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _195);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, vertex_color1, vertex_uv1, _149, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _226, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _226.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _238.x;\n    _745.y = _238.y;\n    _745.z = _238.z;\n    base_t = _745;\n    float4 _253 = (_745 * _226.fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_226.fa_maps.z > 0.5)\n    {\n        float param_4 = _226.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _226.fa_maps.x;\n        float3 _753 = _290;\n        _753.x = _295.x;\n        _753.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _226.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _324.x;\n    _756.y = _324.y;\n    _756.z = _324.z;\n    mrt = _756;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _226.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _713 = _226.fa_layers_a.x;\n    float _714 = _226.fa_layers_a.y;\n    float _717 = _226.fa_layers_a.z;\n    float _716 = _226.fa_layers_b.w;\n    float _719 = _226.fa_layers_c.x;\n    if (_226.fa_layers_c.z > 0.5)\n    {\n        if (mod(_226.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _713 *= _366.y;\n            _714 *= _366.z;\n            _716 *= _354.w;\n        }\n        if (_226.fa_layers_c.z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _708, fast::clamp(_226.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_226.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_226.fa_maps.y * (_366.x - 1.0)), _226.fa_emissive.xyz + (_226.fa_model_emissive.xyz * _396), _713, _714, _226.fa_layers_b.xyz, _716, _717, _226.fa_layers_a.w, _719, _226.fa_layers_c.y, _226.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _226 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _619 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _530 = fast::normalize(_226.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _226, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _545 = fast::normalize(param_2.normal);\n    float3 _560 = fast::normalize(float3(dot(in.fa_pre_r0, _545), dot(in.fa_pre_r1, _545), dot(in.fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / float2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_195",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _135)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _135 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _135);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    out.gl_Position = _135.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_135",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _186)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_186.fa_joint_rows[_177] * weights[i]);\n        r1 += (_186.fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186.fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _140)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _140 [[buffer(0)]], constant fa_skin& _186 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _186);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _140);\n    vertex0(param_8, vertex_color1, vertex_uv1);\n    out.gl_Position = _140.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_140",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
