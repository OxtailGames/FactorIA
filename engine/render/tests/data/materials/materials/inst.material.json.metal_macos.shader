{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2588 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    bool _547 = _542.fa_cl_info.x < 0.0;\n    bool _554;\n    if (!_547)\n    {\n        _554 = _542.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _554 = _547;\n    }\n    bool _562;\n    if (!_554)\n    {\n        _562 = _542.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _562 = _554;\n    }\n    bool _569;\n    if (!_562)\n    {\n        _569 = _542.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _569 = _562;\n    }\n    bool _576;\n    if (!_569)\n    {\n        _576 = _542.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _576 = _569;\n    }\n    if (_576)\n    {\n        return float4(0.0);\n    }\n    float4 _586 = float4(world_pos, 1.0);\n    float _593 = dot(_542.fa_cl_vpw, _586);\n    if (!(_593 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _615 = float2(dot(_542.fa_cl_vpx, _586), dot(_542.fa_cl_vpy, _586)) / float2(_593);\n    int _619 = int(_542.fa_cl_grid.x);\n    int _623 = int(_542.fa_cl_grid.y);\n    int param = (int(_542.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_542.fa_cl_fwd.xyz, world_pos) + _542.fa_cl_fwd.w, _542.fa_cl_grid.w) / _542.fa_cl_grid.w) * _542.fa_cl_grid.z)), 0, int(_542.fa_cl_info.y) - 1) * _623) + clamp(int(floor(((_615.y * 0.5) + 0.5) * _542.fa_cl_grid.y)), 0, _623 - 1)) * _619)) + clamp(int(floor(((_615.x * 0.5) + 0.5) * _542.fa_cl_grid.x)), 0, _619 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _542);\n    return int2(int(_699.x), int(_699.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_542.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3403 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _542);\n    fa_cl_slot = _3403.x;\n    fa_cl_local = _3403.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3578 = fa_linear_to_srgb(param);\n        c = _3578;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3586 = fa_srgb_to_linear(param_1);\n            c = _3586;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _542, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _542.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3617 = fa_tex_fix(param_2, param_3);\n    float4 _4916 = base_t;\n    _4916.x = _3617.x;\n    _4916.y = _3617.y;\n    _4916.z = _3617.z;\n    base_t = _4916;\n    float4 _3631 = (_4916 * _542.fa_base_color) * i.vertex_color;\n    float3 _4783 = i.world_normal;\n    if (_542.fa_maps.z > 0.5)\n    {\n        float param_4 = _542.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3663 = fa_tex_fix(param_6, param_7);\n        float3 _3666 = (_3663 * 2.0) - float3(1.0);\n        float2 _3671 = _3666.xy * _542.fa_maps.x;\n        float3 _4924 = _3666;\n        _4924.x = _3671.x;\n        _4924.y = _3671.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4924;\n        _4783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _542.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3700 = fa_tex_fix(param_12, param_13);\n    float4 _4927 = mrt;\n    _4927.x = _3700.x;\n    _4927.y = _3700.y;\n    _4927.z = _3700.z;\n    mrt = _4927;\n    float4 _3728 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _542.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3728.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3740 = fa_tex_fix(param_16, param_17);\n    float param_18 = _542.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3770 = fa_tex_fix(param_20, param_21);\n    float _4788 = _542.fa_layers_a.x;\n    float _4789 = _542.fa_layers_a.y;\n    float _4792 = _542.fa_layers_a.z;\n    float _4791 = _542.fa_layers_b.w;\n    float _4794 = _542.fa_layers_c.x;\n    if (_542.fa_layers_c.z > 0.5)\n    {\n        if (mod(_542.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4788 *= _3740.y;\n            _4789 *= _3740.z;\n            _4791 *= _3728.w;\n        }\n        if (_542.fa_layers_c.z > 1.5)\n        {\n            _4792 *= mrt.x;\n            _4794 *= mrt.w;\n        }\n    }\n    return Surface{ _3631.xyz, _3631.w, _4783, fast::clamp(_542.fa_pbr.x * _3700.z, 0.0, 1.0), fast::clamp(_542.fa_pbr.y * _3700.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_542.fa_maps.y * (_3740.x - 1.0)), _542.fa_emissive.xyz + (_542.fa_model_emissive.xyz * _3770), _4788, _4789, _542.fa_layers_b.xyz, _4791, _4792, _542.fa_layers_a.w, _4794, _542.fa_layers_c.y, _542.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3526)\n{\n    s.emission += ((tint.xyz * tint.w) * _3526.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _780 = rect.zw - rect.xy;\n    float2 _784 = _780 * atlas;\n    float2 _788 = ddx * _784;\n    float2 _792 = ddy * _784;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _780)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_788, _788), dot(_792, _792)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _827 = _542.fa_counts.y < 0.5;\n    bool _834;\n    if (!_827)\n    {\n        _834 = _542.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _834 = _827;\n    }\n    if (_834)\n    {\n        return;\n    }\n    float3 _840 = dfdx(world_pos);\n    float3 _843 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _847 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _542);\n    int _851 = int(_847.w);\n    if (_851 < 1)\n    {\n        return;\n    }\n    int _861 = int(_542.fa_counts.y + 0.5);\n    int param_1 = _861;\n    float4 _865 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _868 = _865.yz;\n    int _872 = int(_865.w);\n    int param_2 = _861 + 1;\n    float4 _877 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _878 = _877.x;\n    int _884 = int(_542.fa_counts.w + 0.5) - 1;\n    int _888 = int(_847.z);\n    float3 _1154;\n    for (int k = 0; k < _851; k++)\n    {\n        int _901 = _888 + k;\n        int param_3 = _872 + (_901 >> 2);\n        int _919 = (_861 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_901 & 3]) * 7);\n        int param_4 = _919 + 6;\n        float4 _924 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_924.w + 0.5) >> _884) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _919;\n        float4 _939 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _919 + 1;\n        float4 _944 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _919 + 2;\n        float4 _949 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _952 = _939.xyz;\n        float _957 = dot(_952, world_pos) + _939.w;\n        float3 _959 = _944.xyz;\n        float _964 = dot(_959, world_pos) + _944.w;\n        float3 _966 = _949.xyz;\n        float _971 = dot(_966, world_pos) + _949.w;\n        bool _976 = abs(_957) > 0.5;\n        bool _984;\n        if (!_976)\n        {\n            _984 = abs(_964) > 0.5;\n        }\n        else\n        {\n            _984 = _976;\n        }\n        bool _992;\n        if (!_984)\n        {\n            _992 = abs(_971) > 0.5;\n        }\n        else\n        {\n            _992 = _984;\n        }\n        if (_992)\n        {\n            continue;\n        }\n        float _1007 = fast::clamp(dot(geo_normal, fast::normalize(_966)) * _924.z, 0.0, 1.0);\n        if (_1007 <= 0.0)\n        {\n            continue;\n        }\n        float _1027 = (fast::clamp((0.5 - abs(_971)) * 10.0, 0.0, 1.0) * _1007) * _924.x;\n        float2 _1035 = float2(_957 + 0.5, 0.5 - _964);\n        float2 _1045 = float2(dot(_952, _840), dot(_959, _840));\n        float2 _1055 = float2(dot(_952, _843), dot(_959, _843));\n        int param_8 = _919 + 5;\n        float4 _1060 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _919 + 3;\n        float4 _1065 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _919 + 4;\n        float4 _1070 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1060.xyz;\n        bool _1080 = _1065.z > _1065.x;\n        if (_1080)\n        {\n            float4 param_11 = _1065;\n            float2 param_12 = _1035;\n            float2 param_13 = _868;\n            float2 param_14 = _1045;\n            float2 param_15 = _1055;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_878 > 0.5) && (_878 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1106 = fa_dc_to_linear(param_16);\n                float4 _4839 = tx;\n                _4839.x = _1106.x;\n                _4839.y = _1106.y;\n                _4839.z = _1106.z;\n                tx = _4839;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1027 * tex_a) * _1060.w, 0.0, 1.0)));\n        if (_1070.z > _1070.x)\n        {\n            float4 param_17 = _1070;\n            float2 param_18 = _1035;\n            float2 param_19 = _868;\n            float2 param_20 = _1045;\n            float2 param_21 = _1055;\n            float4 _1150 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_878 > 1.5)\n            {\n                float3 param_22 = _1150.xyz;\n                float3 _1160 = fa_dc_to_srgb(param_22);\n                _1154 = _1160;\n            }\n            else\n            {\n                _1154 = _1150.xyz;\n            }\n            float3 _1170 = (_1154 * 2.0) - float3(1.0);\n            float2 _1175 = _1170.xy * _924.y;\n            float3 _1197 = (fast::normalize(_952) * _1175.x) + (fast::normalize(_959) * _1175.y);\n            float3 _1200 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1200, fast::normalize((_1200 * fast::max(_1170.z, 0.0500000007450580596923828125)) + (_1197 - (_1200 * dot(_1200, _1197)))), float3(fast::clamp(_1027 * (_1080 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2513 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2521 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2524 = int(_2513);\n    int _2527 = int(_2521);\n    float _2537 = _2521 - float(_2527);\n    int _2593 = (_2524 * 9) + _2527;\n    int _2613 = ((_2524 + 1) * 9) + _2527;\n    return mix(mix(_2588[_2593], _2588[_2593 + 1], _2537), mix(_2588[_2613], _2588[_2613 + 1], _2537), _2513 - float(_2524));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4706 = false;\n    float _4707 = 1.0;\n    float _4708 = 1.0;\n    float _4709 = 1.0;\n    float _4710 = 0.0;\n    float _4711 = 0.0;\n    float _4712 = 0.0;\n    float _4713 = 0.0;\n    float _4715 = 1.0;\n    bool _4716 = false;\n    float3 _4717 = float3(0.0);\n    float _4718 = 1.0;\n    float _4719 = 1.0;\n    float _4720 = 1.0;\n    float _4721 = 0.0;\n    float _4722 = 0.0;\n    float3 _4723 = float3(1.0, 0.0, 0.0);\n    float3 _4724 = float3(0.0, 0.0, 1.0);\n    float _4725 = 1.0;\n    float _4726 = 1.0;\n    float _2666 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2670 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2675 = (_2666 != 1.0) || (_2670 != 1.5);\n    bool _2685;\n    if (!_2675)\n    {\n        _2685 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2685 = _2675;\n    }\n    if (_2685)\n    {\n        float _2693 = (_2670 - 1.0) / (_2670 + 1.0);\n        f0 = mix(fast::min(float3(_2693 * _2693) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2666, s.albedo, float3(metallic));\n        _4707 = mix(_2666, 1.0, metallic);\n        _4706 = true;\n    }\n    float _2721 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2721 > 0.0)\n    {\n        float _2729 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4710 = _2721;\n        _4711 = _2729;\n        float _2736 = _2729 * _2729;\n        _4712 = _2736;\n        _4713 = _2736 * _2736;\n        float _2748 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4715 = _2748;\n        _4708 = 1.0 - (_2721 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2748, 0.0, 1.0), 5.0))));\n        _4706 = true;\n    }\n    float3 _2768 = fast::max(s.sheen_color, float3(0.0));\n    float _2777 = fast::max(_2768.x, fast::max(_2768.y, _2768.z));\n    if (_2777 > 0.0)\n    {\n        float _2785 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4716 = true;\n        _4717 = _2768;\n        _4718 = _2785;\n        _4719 = _2785 * _2785;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2785;\n        float _2802 = fa_sheen_albedo(param, param_1);\n        _4721 = _2802;\n        _4720 = 1.0 - fast::min(_2777 * _2802, 1.0);\n        _4706 = true;\n    }\n    _4709 = _4708 * _4720;\n    float _2821 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2821 != 0.0)\n    {\n        float3 _2836 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2836;\n        if (dot(_2836, _2836) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2853 = t;\n        float3 _2854 = fast::normalize(_2853);\n        t = _2854;\n        float3 _2879 = fast::normalize((_2854 * cos(s.anisotropy_rotation)) + ((cross(n, _2854) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4723 = _2879;\n        _4724 = cross(n, _2879);\n        float _2889 = roughness * roughness;\n        float _2895 = mix(_2889, 1.0, _2821 * _2821);\n        bool _2897 = _2821 > 0.0;\n        _4725 = _2897 ? _2895 : _2889;\n        _4726 = _2897 ? _2889 : _2895;\n        _4722 = _2821;\n        _4706 = true;\n    }\n    return FaLayers{ short(_4706), _4707, _4708, _4709, _4710, _4711, _4712, _4713, i.world_normal, _4715, short(_4716), _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_542.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _542.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _542, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    int param = (int(_542.fa_cl_info.x) + int(_542.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _542);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _416 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _422 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _425 = _422.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _431 = _425 < 0.5;\n    float3 l;\n    if (_431)\n    {\n        l = fast::normalize(_416.xyz);\n    }\n    else\n    {\n        float3 _443 = _416.xyz - world_pos;\n        float _445 = length(_443);\n        dist = _445;\n        l = _443 / float3(fast::max(_445, 9.9999997473787516355514526367188e-05));\n        float _460 = _445 / fast::max(_416.w, 0.001000000047497451305389404296875);\n        float _466 = fast::clamp(1.0 - (_460 * _460), 0.0, 1.0);\n        atten = _466 * _466;\n        if (_425 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _480 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _490 = _480.w;\n            int param_3 = (li * 4) + 3;\n            float4 _496 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _497 = _496.x;\n            float cos_inner = _497;\n            if (_497 > 1.5)\n            {\n                cos_inner = mix(_490, 1.0, 0.25);\n            }\n            atten *= smoothstep(_490, cos_inner, dot(-l, fast::normalize(_480.xyz)));\n        }\n    }\n    int _528;\n    if (_431)\n    {\n        _528 = 0;\n    }\n    else\n    {\n        _528 = (_425 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _422.xyz * atten, atten, 1.0, dist, _528 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1282)\n{\n    float _1272;\n    if (i == 0)\n    {\n        _1272 = _1282.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1288;\n        if (i == 1)\n        {\n            _1288 = _1282.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1296;\n            if (i == 2)\n            {\n                _1296 = _1282.fa_shadow_split.z;\n            }\n            else\n            {\n                _1296 = _1282.fa_shadow_split.w;\n            }\n            _1288 = _1296;\n        }\n        _1272 = _1288;\n    }\n    return _1272;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1329 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1333;\n    if (conv.x < 0.5)\n    {\n        _1333 = _1329;\n    }\n    else\n    {\n        _1333 = (conv.y * conv.z) / (conv.z - (_1329 * (conv.z - conv.y)));\n    }\n    return _1333;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1260 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1260), sin(_1260)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1379 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1393 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1379;\n            float2 _1412 = fa_shadow_vogel(param_3, param_4, param_5) * _1393;\n            float2 param_6 = uv + (_1412 * _1282.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1424 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1424 < (zr - (length(_1412) * plane)))\n            {\n                sum += _1424;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1468 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1468; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1468;\n        float param_11 = _1379;\n        float2 _1487 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1487 * _1282.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1487) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1468);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    float _1529 = fast::max(_1282.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1534 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1540 = sqrt(1.0 - (_1534 * _1534));\n    float _1547 = fast::min(_1540 / fast::max(_1534, 0.20000000298023223876953125), 4.0);\n    float _1552;\n    if (_1282.fa_shadow_bias.y > 0.0)\n    {\n        _1552 = _1282.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1552 = 1.5 * _1282.fa_shadow_info[ci].x;\n    }\n    float4 _1577 = _1282.fa_shadow_mat[ci] * float4(world + (n * (_1552 * _1540)), 1.0);\n    float _1584 = _1577.x;\n    bool _1587 = _1584 < _1282.fa_shadow_rect[ci].x;\n    bool _1596;\n    if (!_1587)\n    {\n        _1596 = _1584 > _1282.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1596 = _1587;\n    }\n    bool _1605;\n    if (!_1596)\n    {\n        _1605 = _1577.y < _1282.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1605 = _1596;\n    }\n    bool _1614;\n    if (!_1605)\n    {\n        _1614 = _1577.y > _1282.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1614 = _1605;\n    }\n    bool _1621;\n    if (!_1614)\n    {\n        _1621 = _1577.z > 1.0;\n    }\n    else\n    {\n        _1621 = _1614;\n    }\n    if (_1621)\n    {\n        return -1.0;\n    }\n    float _1630;\n    if (_1282.fa_shadow_bias.x > 0.0)\n    {\n        _1630 = _1282.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1630 = 1.5 * _1282.fa_shadow_info[ci].x;\n    }\n    float2 param = _1577.xy;\n    float4 param_1 = _1282.fa_shadow_rect[ci];\n    float param_2 = _1577.z - ((_1630 * (1.0 + (0.5 * _1547))) / _1529);\n    float param_3 = _1282.fa_shadow_info[ci].x;\n    float param_4 = _1529;\n    float param_5 = _1529 * 0.25;\n    float param_6 = ((_1282.fa_shadow_info[ci].x * fast::min(_1547, 3.0)) * 0.5) / _1529;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1282.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1282.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    if (_542.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2057 = int(_1282.fa_shadow_cfg.x + 0.5);\n    if (_2057 < 1)\n    {\n        return 1.0;\n    }\n    float _2072 = dot(world - _1282.fa_shadow_eye.xyz, _1282.fa_shadow_fwd.xyz);\n    int param = _2057 - 1;\n    if (_2072 > fa_shadow_split_at(param, _1282))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2084 = _2057 > 1;\n    bool _2091;\n    if (_2084)\n    {\n        _2091 = _2072 > _1282.fa_shadow_split.x;\n    }\n    else\n    {\n        _2091 = _2084;\n    }\n    if (_2091)\n    {\n        ci = 1;\n    }\n    bool _2095 = _2057 > 2;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2072 > _1282.fa_shadow_split.y;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 2;\n    }\n    bool _2106 = _2057 > 3;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2072 > _1282.fa_shadow_split.z;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2057)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2139 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n        s = _2139;\n        if (_2139 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1282.fa_shadow_cfg.y > 0.0)\n    {\n        float _2164;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2164 = fa_shadow_split_at(param_5, _1282);\n        }\n        else\n        {\n            _2164 = _1282.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2183 = _1282.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1282) - _2164, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2194 = fast::clamp((_2072 - (fa_shadow_split_at(param_7, _1282) - _2183)) / _2183, 0.0, 1.0);\n        if (_2194 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2057)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2215 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n                s2 = _2215;\n                if (_2215 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2194);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    bool _1688 = _542.fa_pbr.z < 0.5;\n    bool _1696;\n    if (!_1688)\n    {\n        _1696 = _1282.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1696 = _1688;\n    }\n    if (_1696)\n    {\n        return 1.0;\n    }\n    int param = (int(_1282.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1709 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1710 = _1709.x;\n    if (_1710 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1719 = int(_1710 + 0.5);\n    int param_1 = _1719;\n    float4 _1723 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1719 + 1;\n    float4 _1728 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1731 = _1723.y;\n    if (_1731 > 0.0)\n    {\n        float _1748 = 1.0 - smoothstep(0.75 * _1731, _1731, length(world - _1282.fa_shadow_eye.xyz));\n        fade = _1748;\n        if (_1748 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1723.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1767 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1770 = abs(_1767);\n        float _1772 = _1770.x;\n        float _1774 = _1770.y;\n        bool _1775 = _1772 >= _1774;\n        bool _1783;\n        if (_1775)\n        {\n            _1783 = _1772 >= _1770.z;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        int _1784;\n        if (_1783)\n        {\n            _1784 = (_1767.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1797;\n            if (_1774 >= _1770.z)\n            {\n                _1797 = (_1767.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1797 = (_1767.z > 0.0) ? 4 : 5;\n            }\n            _1784 = _1797;\n        }\n        face = _1784;\n    }\n    int _1816 = (_1719 + 2) + (face * 6);\n    int param_4 = _1816;\n    int param_5 = _1816 + 1;\n    int param_6 = _1816 + 3;\n    float4 _1830 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1816 + 4;\n    float4 _1835 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1816 + 5;\n    float4 _1840 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1852 = _1840.x * fast::max(dot(_1830, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1857 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1880 = fast::clamp(dot(n, _1830.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1903 = fast::min(sqrt(1.0 - (_1880 * _1880)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1830, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1906 = _1728.y;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1852;\n    }\n    float4 _1928 = float4(world + (n * (_1908 * sqrt(1.0 - (_1857 * _1857)))), 1.0);\n    float _1932 = dot(_1830, _1928);\n    float _1935 = _1840.y;\n    if (_1932 < _1935)\n    {\n        return 1.0;\n    }\n    float2 _1950 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1928), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1928)) / float2(_1932);\n    float _1952 = _1950.x;\n    bool _1955 = _1952 < _1835.x;\n    bool _1964;\n    if (!_1955)\n    {\n        _1964 = _1952 > _1835.z;\n    }\n    else\n    {\n        _1964 = _1955;\n    }\n    bool _1973;\n    if (!_1964)\n    {\n        _1973 = _1950.y < _1835.y;\n    }\n    else\n    {\n        _1973 = _1964;\n    }\n    bool _1982;\n    if (!_1973)\n    {\n        _1982 = _1950.y > _1835.w;\n    }\n    else\n    {\n        _1982 = _1973;\n    }\n    if (_1982)\n    {\n        return 1.0;\n    }\n    float _1988 = _1728.x;\n    float _1990;\n    if (_1988 > 0.0)\n    {\n        _1990 = _1988;\n    }\n    else\n    {\n        _1990 = 1.5 * _1852;\n    }\n    float2 param_10 = _1950;\n    float4 param_11 = _1835;\n    float param_12 = _1932 - (_1990 * (1.0 + (0.5 * _1903)));\n    float param_13 = _1852;\n    float param_14 = 1.0;\n    float param_15 = _1840.z * 0.25;\n    float param_16 = (_1852 * fast::min(_1903, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1935, _1840.z);\n    int param_18 = int(_1723.z + 0.5);\n    float param_19 = _1723.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3430 = fa_lm.z > 0.5;\n    bool _3436;\n    if (_3430)\n    {\n        int param = li;\n        _3436 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3436 = _3430;\n    }\n    if (_3436)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3458 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4768 = _3458.direction;\n    float3 _4763 = _3458.color;\n    float _4770 = _3458.attenuation;\n    float _4765 = _3458.shadow;\n    int _4773 = _3458.type;\n    if ((_4773 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4768;\n        float _3472 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex, fa_world_pos);\n        _4765 = _3472;\n        _4763 *= _3472;\n    }\n    else\n    {\n        bool _3483 = _4773 != 0;\n        bool _3489;\n        if (_3483)\n        {\n            _3489 = _4770 > 0.0;\n        }\n        else\n        {\n            _3489 = _3483;\n        }\n        if (_3489)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4768;\n            float _3501 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex);\n            _4765 = _3501;\n            _4763 *= _3501;\n        }\n    }\n    return LightSample{ _4768, _4763, _4770, _4765, _3458._distance, _4773 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3047 = tdh / at;\n    float _3051 = bdh / ab;\n    float _3063 = ((_3047 * _3047) + (_3051 * _3051)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3063) * _3063);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3144 = 1.0 / alpha;\n    return ((2.0 + _3144) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3144)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3176 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3255 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3255) * _3255);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3176);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3176));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3328 = fast::max(dot(L.nc, l), 0.0);\n        float _3334 = fast::max(dot(L.nc, h), 0.0);\n        float _3343 = ((_3334 * _3334) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3343) * _3343)) * (0.5 / fast::max(mix((2.0 * _3328) * L.coat_ndv, _3328 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3328)) * _3328);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2445 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2448 = _2445.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2448 * _2448, exp2((-9.27999973297119140625) * ndv)) * _2448) + _2445.y)) + _2445.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_542.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _542.fa_env_horizon.w)).xyz;\n    }\n    float _2351 = rough * rough;\n    float _2381 = 0.60000002384185791015625 * _2351;\n    return mix(mix(_542.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_542.fa_env_horizon.xyz, _542.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2351)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2381, 0.0500000007450580596923828125 + _2381, d.y))), ((_542.fa_env_sky.xyz + _542.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2351 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2930;\n        if (L.aniso >= 0.0)\n        {\n            _2930 = L.b;\n        }\n        else\n        {\n            _2930 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2930, v), _2930), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2963 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _542, fa_env_smp, fa_env_tex) * ((f0 * _2963.x) + (float3(L.f90) * _2963.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _542, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3018 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _542, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3018.x) + _3018.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2487 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _542, fa_env_smp, fa_env_tex) * ((f0 * _2487.x) + float3(_2487.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1282)\n{\n    if (_1282.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2239 = int(_1282.fa_shadow_cfg.x + 0.5);\n    float _2249 = dot(world - _1282.fa_shadow_eye.xyz, _1282.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2254 = _2239 > 0;\n    bool _2263;\n    if (_2254)\n    {\n        int param = _2239 - 1;\n        _2263 = _2249 <= fa_shadow_split_at(param, _1282);\n    }\n    else\n    {\n        _2263 = _2254;\n    }\n    if (_2263)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2270 = _2239 > 1;\n        bool _2277;\n        if (_2270)\n        {\n            _2277 = _2249 > _1282.fa_shadow_split.x;\n        }\n        else\n        {\n            _2277 = _2270;\n        }\n        if (_2277)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2283 = _2239 > 2;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2249 > _1282.fa_shadow_split.y;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2296 = _2239 > 3;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2249 > _1282.fa_shadow_split.z;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _542 [[buffer(1)]], constant fa_material& _3526 [[buffer(5)]], constant fa_shadows& _1282 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4485 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4485 = -_4485;\n    }\n    float3 _3910 = fast::normalize(_542.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _542, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n    Surface _3918 = fa_standard_surface(param_1, _542, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4516 = _3918.albedo;\n    float _4517 = _3918.alpha;\n    float3 _4518 = _3918.normal;\n    float _4519 = _3918.metallic;\n    float _4520 = _3918.roughness;\n    float _4521 = _3918.occlusion;\n    float3 _4522 = _3918.emission;\n    float _4523 = _3918.clearcoat;\n    float _4524 = _3918.clearcoat_roughness;\n    float3 _4525 = _3918.sheen_color;\n    float _4526 = _3918.sheen_roughness;\n    float _4527 = _3918.anisotropy;\n    float _4528 = _3918.anisotropy_rotation;\n    float _4529 = _3918.specular;\n    float _4530 = _3918.ior;\n    float3 _4531 = _3918.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n    Surface param_3 = _3918;\n    surface(param_2, param_3, tint, _3526);\n    _4516 = param_3.albedo;\n    _4517 = param_3.alpha;\n    _4518 = param_3.normal;\n    _4519 = param_3.metallic;\n    _4520 = param_3.roughness;\n    _4521 = param_3.occlusion;\n    _4522 = param_3.emission;\n    _4523 = param_3.clearcoat;\n    _4524 = param_3.clearcoat_roughness;\n    _4525 = param_3.sheen_color;\n    _4526 = param_3.sheen_roughness;\n    _4527 = param_3.anisotropy;\n    _4528 = param_3.anisotropy_rotation;\n    _4529 = param_3.specular;\n    _4530 = param_3.ior;\n    _4531 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4485;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _542, fa_decal_tex, fa_env_smp);\n    _4516 = param_6;\n    _4518 = param_7;\n    float3 result;\n    if (_542.fa_emissive.w > 0.5)\n    {\n        result = _4516;\n    }\n    else\n    {\n        float3 _3957 = fast::normalize(_4518);\n        float _3964 = fast::clamp(_4519, 0.0, 1.0);\n        float _3968 = fast::clamp(_4520, 0.0500000007450580596923828125, 1.0);\n        float _3972 = _3968 * _3968;\n        float _3976 = _3972 * _3972;\n        float _3981 = fast::max(dot(_3957, _3910), 9.9999997473787516355514526367188e-05);\n        float3 _3987 = _4516 * (1.0 - _3964);\n        float3 _3994 = mix(float3(0.039999999105930328369140625), _4516, float3(_3964));\n        float3 f0 = _3994;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4516, _4517, _4518, _4519, _4520, _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531 };\n        float3 param_10 = _3957;\n        float3 param_11 = _3910;\n        float param_12 = _3964;\n        float param_13 = _3968;\n        float3 param_14 = _3994;\n        FaLayers _4010 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3957;\n        float3 lit = (fa_indirect_diffuse(param_15, _542, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3987) * _4521;\n        if (_4010.on)\n        {\n            lit *= _4010.base_scale;\n        }\n        int _4032 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4032; ln++)\n        {\n            int param_16 = ln;\n            int _4045 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _542, fa_cl_ndir, fa_cl_slot);\n            bool _4048 = in.fa_lm.z > 0.5;\n            bool _4054;\n            if (_4048)\n            {\n                int param_17 = _4045;\n                _4054 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4054 = _4048;\n            }\n            if (_4054)\n            {\n                continue;\n            }\n            int param_18 = _4045;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4485;\n            LightSample _4066 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4690 = _4066.direction;\n            float _4074 = fast::max(dot(_3957, _4690), 0.0);\n            float _4080 = _4066.attenuation * _4066.shadow;\n            float3 _4085 = fast::normalize(_4690 + _3910);\n            float _4090 = fast::max(dot(_3957, _4085), 0.0);\n            float _4095 = fast::max(dot(_3910, _4085), 0.0);\n            if (_4010.on)\n            {\n                FaLayers param_21 = _4010;\n                float3 param_22 = _3987;\n                float3 param_23 = f0;\n                float3 param_24 = _3957;\n                float3 param_25 = _3910;\n                float3 param_26 = _4690;\n                float3 param_27 = _4085;\n                float param_28 = _4074;\n                float param_29 = _3981;\n                float param_30 = _4090;\n                float param_31 = _4095;\n                float param_32 = _3972;\n                float param_33 = _3976;\n                int param_34 = _4045;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4080));\n            }\n            else\n            {\n                float _4143 = ((_4090 * _4090) * (_3976 - 1.0)) + 1.0;\n                int param_35 = _4045;\n                lit += (((_3987 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4095, 5.0))) * (((_3976 / ((3.1415927410125732421875 * _4143) * _4143)) * (0.5 / fast::max(mix((2.0 * _4074) * _3981, _4074 + _3981, _3972), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4074))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4074 * _4080));\n            }\n        }\n        if (_4010.on)\n        {\n            FaLayers param_36 = _4010;\n            float3 param_37 = _3957;\n            float3 param_38 = _3910;\n            float3 param_39 = f0;\n            float param_40 = _3968;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _542, fa_env_smp, fa_env_tex) * _4521);\n        }\n        else\n        {\n            float3 param_41 = _3957;\n            float3 param_42 = _3910;\n            float3 param_43 = f0;\n            float param_44 = _3968;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _542, fa_env_smp, fa_env_tex) * _4521);\n        }\n        result = lit;\n    }\n    float3 _4236 = result;\n    float3 _4237 = _4236 + _4522;\n    result = _4237;\n    float3 param_45 = _4237;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1282);\n    bool _4246 = _542.fa_fog.w > 0.0;\n    bool _4253;\n    if (!_4246)\n    {\n        _4253 = _542.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4253 = _4246;\n    }\n    if (_4253)\n    {\n        float3 _4262 = in.fa_world_pos - _542.fa_camera_pos.xyz;\n        float _4268 = dot(_4262, _542.fa_fog_c.xyz);\n        bool _4272 = _542.fa_fog_c.w > 0.5;\n        float _4273;\n        if (_4272)\n        {\n            _4273 = _4268;\n        }\n        else\n        {\n            _4273 = length(_4262);\n        }\n        float _4285 = _4273 - _542.fa_fog_b.x;\n        if (_4285 > 0.0)\n        {\n            float _4294 = _542.fa_fog.w * _4285;\n            float tau = _4294 * _4294;\n            if (_542.fa_fog_b.y > 0.0)\n            {\n                float _4310;\n                if (_4272)\n                {\n                    _4310 = in.fa_world_pos.y - (_542.fa_fog_c.y * _4268);\n                }\n                else\n                {\n                    _4310 = _542.fa_camera_pos.y;\n                }\n                float _4331 = mix(_4310, in.fa_world_pos.y, fast::clamp(_542.fa_fog_b.x / _4273, 0.0, 1.0));\n                float _4335 = in.fa_world_pos.y - _4331;\n                float _4340 = _4331 - _542.fa_fog_b.z;\n                float _4345 = in.fa_world_pos.y - _542.fa_fog_b.z;\n                bool _4348 = _4340 <= 0.0;\n                bool _4349 = !_4348;\n                bool _4355;\n                if (_4349)\n                {\n                    _4355 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4355 = _4348;\n                }\n                float _4356;\n                if (_4355)\n                {\n                    _4356 = _542.fa_fog_b.y;\n                }\n                else\n                {\n                    _4356 = _542.fa_fog_b.y * exp(-fast::min(_542.fa_fog_b.w * _4340, 80.0));\n                }\n                bool _4383;\n                if (_4349)\n                {\n                    _4383 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4383 = _4348;\n                }\n                float _4384;\n                if (_4383)\n                {\n                    _4384 = _542.fa_fog_b.y * _4340;\n                }\n                else\n                {\n                    _4384 = (_542.fa_fog_b.y * (1.0 - exp(-fast::min(_542.fa_fog_b.w * _4340, 80.0)))) / _542.fa_fog_b.w;\n                }\n                bool _4409 = _4345 <= 0.0;\n                bool _4416;\n                if (!_4409)\n                {\n                    _4416 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4416 = _4409;\n                }\n                float _4417;\n                if (_4416)\n                {\n                    _4417 = _542.fa_fog_b.y * _4345;\n                }\n                else\n                {\n                    _4417 = (_542.fa_fog_b.y * (1.0 - exp(-fast::min(_542.fa_fog_b.w * _4345, 80.0)))) / _542.fa_fog_b.w;\n                }\n                float _4444;\n                if (abs(_4335) < 0.001000000047497451305389404296875)\n                {\n                    _4444 = _4356;\n                }\n                else\n                {\n                    _4444 = (_4417 - _4384) / _4335;\n                }\n                tau += (_4285 * fast::max(_4444, 0.0));\n            }\n            result = mix(result, _542.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4517);\n    return out;\n}\n\n",
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
            "inst_name": "_542",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1282",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3526",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2588 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    bool _547 = _542.fa_cl_info.x < 0.0;\n    bool _554;\n    if (!_547)\n    {\n        _554 = _542.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _554 = _547;\n    }\n    bool _562;\n    if (!_554)\n    {\n        _562 = _542.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _562 = _554;\n    }\n    bool _569;\n    if (!_562)\n    {\n        _569 = _542.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _569 = _562;\n    }\n    bool _576;\n    if (!_569)\n    {\n        _576 = _542.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _576 = _569;\n    }\n    if (_576)\n    {\n        return float4(0.0);\n    }\n    float4 _586 = float4(world_pos, 1.0);\n    float _593 = dot(_542.fa_cl_vpw, _586);\n    if (!(_593 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _615 = float2(dot(_542.fa_cl_vpx, _586), dot(_542.fa_cl_vpy, _586)) / float2(_593);\n    int _619 = int(_542.fa_cl_grid.x);\n    int _623 = int(_542.fa_cl_grid.y);\n    int param = (int(_542.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_542.fa_cl_fwd.xyz, world_pos) + _542.fa_cl_fwd.w, _542.fa_cl_grid.w) / _542.fa_cl_grid.w) * _542.fa_cl_grid.z)), 0, int(_542.fa_cl_info.y) - 1) * _623) + clamp(int(floor(((_615.y * 0.5) + 0.5) * _542.fa_cl_grid.y)), 0, _623 - 1)) * _619)) + clamp(int(floor(((_615.x * 0.5) + 0.5) * _542.fa_cl_grid.x)), 0, _619 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _542);\n    return int2(int(_699.x), int(_699.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_542.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3403 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _542);\n    fa_cl_slot = _3403.x;\n    fa_cl_local = _3403.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3578 = fa_linear_to_srgb(param);\n        c = _3578;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3586 = fa_srgb_to_linear(param_1);\n            c = _3586;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _542, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _542.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3617 = fa_tex_fix(param_2, param_3);\n    float4 _4916 = base_t;\n    _4916.x = _3617.x;\n    _4916.y = _3617.y;\n    _4916.z = _3617.z;\n    base_t = _4916;\n    float4 _3631 = (_4916 * _542.fa_base_color) * i.vertex_color;\n    float3 _4783 = i.world_normal;\n    if (_542.fa_maps.z > 0.5)\n    {\n        float param_4 = _542.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3663 = fa_tex_fix(param_6, param_7);\n        float3 _3666 = (_3663 * 2.0) - float3(1.0);\n        float2 _3671 = _3666.xy * _542.fa_maps.x;\n        float3 _4924 = _3666;\n        _4924.x = _3671.x;\n        _4924.y = _3671.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4924;\n        _4783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _542.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3700 = fa_tex_fix(param_12, param_13);\n    float4 _4927 = mrt;\n    _4927.x = _3700.x;\n    _4927.y = _3700.y;\n    _4927.z = _3700.z;\n    mrt = _4927;\n    float4 _3728 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _542.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3728.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3740 = fa_tex_fix(param_16, param_17);\n    float param_18 = _542.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3770 = fa_tex_fix(param_20, param_21);\n    float _4788 = _542.fa_layers_a.x;\n    float _4789 = _542.fa_layers_a.y;\n    float _4792 = _542.fa_layers_a.z;\n    float _4791 = _542.fa_layers_b.w;\n    float _4794 = _542.fa_layers_c.x;\n    if (_542.fa_layers_c.z > 0.5)\n    {\n        if (mod(_542.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4788 *= _3740.y;\n            _4789 *= _3740.z;\n            _4791 *= _3728.w;\n        }\n        if (_542.fa_layers_c.z > 1.5)\n        {\n            _4792 *= mrt.x;\n            _4794 *= mrt.w;\n        }\n    }\n    return Surface{ _3631.xyz, _3631.w, _4783, fast::clamp(_542.fa_pbr.x * _3700.z, 0.0, 1.0), fast::clamp(_542.fa_pbr.y * _3700.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_542.fa_maps.y * (_3740.x - 1.0)), _542.fa_emissive.xyz + (_542.fa_model_emissive.xyz * _3770), _4788, _4789, _542.fa_layers_b.xyz, _4791, _4792, _542.fa_layers_a.w, _4794, _542.fa_layers_c.y, _542.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3526)\n{\n    s.emission += ((tint.xyz * tint.w) * _3526.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _780 = rect.zw - rect.xy;\n    float2 _784 = _780 * atlas;\n    float2 _788 = ddx * _784;\n    float2 _792 = ddy * _784;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _780)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_788, _788), dot(_792, _792)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _827 = _542.fa_counts.y < 0.5;\n    bool _834;\n    if (!_827)\n    {\n        _834 = _542.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _834 = _827;\n    }\n    if (_834)\n    {\n        return;\n    }\n    float3 _840 = dfdx(world_pos);\n    float3 _843 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _847 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _542);\n    int _851 = int(_847.w);\n    if (_851 < 1)\n    {\n        return;\n    }\n    int _861 = int(_542.fa_counts.y + 0.5);\n    int param_1 = _861;\n    float4 _865 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _868 = _865.yz;\n    int _872 = int(_865.w);\n    int param_2 = _861 + 1;\n    float4 _877 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _878 = _877.x;\n    int _884 = int(_542.fa_counts.w + 0.5) - 1;\n    int _888 = int(_847.z);\n    float3 _1154;\n    for (int k = 0; k < _851; k++)\n    {\n        int _901 = _888 + k;\n        int param_3 = _872 + (_901 >> 2);\n        int _919 = (_861 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_901 & 3]) * 7);\n        int param_4 = _919 + 6;\n        float4 _924 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_924.w + 0.5) >> _884) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _919;\n        float4 _939 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _919 + 1;\n        float4 _944 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _919 + 2;\n        float4 _949 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _952 = _939.xyz;\n        float _957 = dot(_952, world_pos) + _939.w;\n        float3 _959 = _944.xyz;\n        float _964 = dot(_959, world_pos) + _944.w;\n        float3 _966 = _949.xyz;\n        float _971 = dot(_966, world_pos) + _949.w;\n        bool _976 = abs(_957) > 0.5;\n        bool _984;\n        if (!_976)\n        {\n            _984 = abs(_964) > 0.5;\n        }\n        else\n        {\n            _984 = _976;\n        }\n        bool _992;\n        if (!_984)\n        {\n            _992 = abs(_971) > 0.5;\n        }\n        else\n        {\n            _992 = _984;\n        }\n        if (_992)\n        {\n            continue;\n        }\n        float _1007 = fast::clamp(dot(geo_normal, fast::normalize(_966)) * _924.z, 0.0, 1.0);\n        if (_1007 <= 0.0)\n        {\n            continue;\n        }\n        float _1027 = (fast::clamp((0.5 - abs(_971)) * 10.0, 0.0, 1.0) * _1007) * _924.x;\n        float2 _1035 = float2(_957 + 0.5, 0.5 - _964);\n        float2 _1045 = float2(dot(_952, _840), dot(_959, _840));\n        float2 _1055 = float2(dot(_952, _843), dot(_959, _843));\n        int param_8 = _919 + 5;\n        float4 _1060 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _919 + 3;\n        float4 _1065 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _919 + 4;\n        float4 _1070 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1060.xyz;\n        bool _1080 = _1065.z > _1065.x;\n        if (_1080)\n        {\n            float4 param_11 = _1065;\n            float2 param_12 = _1035;\n            float2 param_13 = _868;\n            float2 param_14 = _1045;\n            float2 param_15 = _1055;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_878 > 0.5) && (_878 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1106 = fa_dc_to_linear(param_16);\n                float4 _4839 = tx;\n                _4839.x = _1106.x;\n                _4839.y = _1106.y;\n                _4839.z = _1106.z;\n                tx = _4839;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1027 * tex_a) * _1060.w, 0.0, 1.0)));\n        if (_1070.z > _1070.x)\n        {\n            float4 param_17 = _1070;\n            float2 param_18 = _1035;\n            float2 param_19 = _868;\n            float2 param_20 = _1045;\n            float2 param_21 = _1055;\n            float4 _1150 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_878 > 1.5)\n            {\n                float3 param_22 = _1150.xyz;\n                float3 _1160 = fa_dc_to_srgb(param_22);\n                _1154 = _1160;\n            }\n            else\n            {\n                _1154 = _1150.xyz;\n            }\n            float3 _1170 = (_1154 * 2.0) - float3(1.0);\n            float2 _1175 = _1170.xy * _924.y;\n            float3 _1197 = (fast::normalize(_952) * _1175.x) + (fast::normalize(_959) * _1175.y);\n            float3 _1200 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1200, fast::normalize((_1200 * fast::max(_1170.z, 0.0500000007450580596923828125)) + (_1197 - (_1200 * dot(_1200, _1197)))), float3(fast::clamp(_1027 * (_1080 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2513 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2521 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2524 = int(_2513);\n    int _2527 = int(_2521);\n    float _2537 = _2521 - float(_2527);\n    int _2593 = (_2524 * 9) + _2527;\n    int _2613 = ((_2524 + 1) * 9) + _2527;\n    return mix(mix(_2588[_2593], _2588[_2593 + 1], _2537), mix(_2588[_2613], _2588[_2613 + 1], _2537), _2513 - float(_2524));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4706 = false;\n    float _4707 = 1.0;\n    float _4708 = 1.0;\n    float _4709 = 1.0;\n    float _4710 = 0.0;\n    float _4711 = 0.0;\n    float _4712 = 0.0;\n    float _4713 = 0.0;\n    float _4715 = 1.0;\n    bool _4716 = false;\n    float3 _4717 = float3(0.0);\n    float _4718 = 1.0;\n    float _4719 = 1.0;\n    float _4720 = 1.0;\n    float _4721 = 0.0;\n    float _4722 = 0.0;\n    float3 _4723 = float3(1.0, 0.0, 0.0);\n    float3 _4724 = float3(0.0, 0.0, 1.0);\n    float _4725 = 1.0;\n    float _4726 = 1.0;\n    float _2666 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2670 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2675 = (_2666 != 1.0) || (_2670 != 1.5);\n    bool _2685;\n    if (!_2675)\n    {\n        _2685 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2685 = _2675;\n    }\n    if (_2685)\n    {\n        float _2693 = (_2670 - 1.0) / (_2670 + 1.0);\n        f0 = mix(fast::min(float3(_2693 * _2693) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2666, s.albedo, float3(metallic));\n        _4707 = mix(_2666, 1.0, metallic);\n        _4706 = true;\n    }\n    float _2721 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2721 > 0.0)\n    {\n        float _2729 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4710 = _2721;\n        _4711 = _2729;\n        float _2736 = _2729 * _2729;\n        _4712 = _2736;\n        _4713 = _2736 * _2736;\n        float _2748 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4715 = _2748;\n        _4708 = 1.0 - (_2721 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2748, 0.0, 1.0), 5.0))));\n        _4706 = true;\n    }\n    float3 _2768 = fast::max(s.sheen_color, float3(0.0));\n    float _2777 = fast::max(_2768.x, fast::max(_2768.y, _2768.z));\n    if (_2777 > 0.0)\n    {\n        float _2785 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4716 = true;\n        _4717 = _2768;\n        _4718 = _2785;\n        _4719 = _2785 * _2785;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2785;\n        float _2802 = fa_sheen_albedo(param, param_1);\n        _4721 = _2802;\n        _4720 = 1.0 - fast::min(_2777 * _2802, 1.0);\n        _4706 = true;\n    }\n    _4709 = _4708 * _4720;\n    float _2821 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2821 != 0.0)\n    {\n        float3 _2836 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2836;\n        if (dot(_2836, _2836) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2853 = t;\n        float3 _2854 = fast::normalize(_2853);\n        t = _2854;\n        float3 _2879 = fast::normalize((_2854 * cos(s.anisotropy_rotation)) + ((cross(n, _2854) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4723 = _2879;\n        _4724 = cross(n, _2879);\n        float _2889 = roughness * roughness;\n        float _2895 = mix(_2889, 1.0, _2821 * _2821);\n        bool _2897 = _2821 > 0.0;\n        _4725 = _2897 ? _2895 : _2889;\n        _4726 = _2897 ? _2889 : _2895;\n        _4722 = _2821;\n        _4706 = true;\n    }\n    return FaLayers{ short(_4706), _4707, _4708, _4709, _4710, _4711, _4712, _4713, i.world_normal, _4715, short(_4716), _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_542.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _542.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _542, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542)\n{\n    int param = (int(_542.fa_cl_info.x) + int(_542.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _542);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _416 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _422 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _425 = _422.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _431 = _425 < 0.5;\n    float3 l;\n    if (_431)\n    {\n        l = fast::normalize(_416.xyz);\n    }\n    else\n    {\n        float3 _443 = _416.xyz - world_pos;\n        float _445 = length(_443);\n        dist = _445;\n        l = _443 / float3(fast::max(_445, 9.9999997473787516355514526367188e-05));\n        float _460 = _445 / fast::max(_416.w, 0.001000000047497451305389404296875);\n        float _466 = fast::clamp(1.0 - (_460 * _460), 0.0, 1.0);\n        atten = _466 * _466;\n        if (_425 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _480 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _490 = _480.w;\n            int param_3 = (li * 4) + 3;\n            float4 _496 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _497 = _496.x;\n            float cos_inner = _497;\n            if (_497 > 1.5)\n            {\n                cos_inner = mix(_490, 1.0, 0.25);\n            }\n            atten *= smoothstep(_490, cos_inner, dot(-l, fast::normalize(_480.xyz)));\n        }\n    }\n    int _528;\n    if (_431)\n    {\n        _528 = 0;\n    }\n    else\n    {\n        _528 = (_425 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _422.xyz * atten, atten, 1.0, dist, _528 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1282)\n{\n    float _1272;\n    if (i == 0)\n    {\n        _1272 = _1282.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1288;\n        if (i == 1)\n        {\n            _1288 = _1282.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1296;\n            if (i == 2)\n            {\n                _1296 = _1282.fa_shadow_split.z;\n            }\n            else\n            {\n                _1296 = _1282.fa_shadow_split.w;\n            }\n            _1288 = _1296;\n        }\n        _1272 = _1288;\n    }\n    return _1272;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1329 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1333;\n    if (conv.x < 0.5)\n    {\n        _1333 = _1329;\n    }\n    else\n    {\n        _1333 = (conv.y * conv.z) / (conv.z - (_1329 * (conv.z - conv.y)));\n    }\n    return _1333;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1260 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1260), sin(_1260)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1379 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1393 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1379;\n            float2 _1412 = fa_shadow_vogel(param_3, param_4, param_5) * _1393;\n            float2 param_6 = uv + (_1412 * _1282.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1424 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1424 < (zr - (length(_1412) * plane)))\n            {\n                sum += _1424;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1468 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1468; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1468;\n        float param_11 = _1379;\n        float2 _1487 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1487 * _1282.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1487) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1468);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    float _1529 = fast::max(_1282.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1534 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1540 = sqrt(1.0 - (_1534 * _1534));\n    float _1547 = fast::min(_1540 / fast::max(_1534, 0.20000000298023223876953125), 4.0);\n    float _1552;\n    if (_1282.fa_shadow_bias.y > 0.0)\n    {\n        _1552 = _1282.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1552 = 1.5 * _1282.fa_shadow_info[ci].x;\n    }\n    float4 _1577 = _1282.fa_shadow_mat[ci] * float4(world + (n * (_1552 * _1540)), 1.0);\n    float _1584 = _1577.x;\n    bool _1587 = _1584 < _1282.fa_shadow_rect[ci].x;\n    bool _1596;\n    if (!_1587)\n    {\n        _1596 = _1584 > _1282.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1596 = _1587;\n    }\n    bool _1605;\n    if (!_1596)\n    {\n        _1605 = _1577.y < _1282.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1605 = _1596;\n    }\n    bool _1614;\n    if (!_1605)\n    {\n        _1614 = _1577.y > _1282.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1614 = _1605;\n    }\n    bool _1621;\n    if (!_1614)\n    {\n        _1621 = _1577.z > 1.0;\n    }\n    else\n    {\n        _1621 = _1614;\n    }\n    if (_1621)\n    {\n        return -1.0;\n    }\n    float _1630;\n    if (_1282.fa_shadow_bias.x > 0.0)\n    {\n        _1630 = _1282.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1630 = 1.5 * _1282.fa_shadow_info[ci].x;\n    }\n    float2 param = _1577.xy;\n    float4 param_1 = _1282.fa_shadow_rect[ci];\n    float param_2 = _1577.z - ((_1630 * (1.0 + (0.5 * _1547))) / _1529);\n    float param_3 = _1282.fa_shadow_info[ci].x;\n    float param_4 = _1529;\n    float param_5 = _1529 * 0.25;\n    float param_6 = ((_1282.fa_shadow_info[ci].x * fast::min(_1547, 3.0)) * 0.5) / _1529;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1282.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1282.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    if (_542.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2057 = int(_1282.fa_shadow_cfg.x + 0.5);\n    if (_2057 < 1)\n    {\n        return 1.0;\n    }\n    float _2072 = dot(world - _1282.fa_shadow_eye.xyz, _1282.fa_shadow_fwd.xyz);\n    int param = _2057 - 1;\n    if (_2072 > fa_shadow_split_at(param, _1282))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2084 = _2057 > 1;\n    bool _2091;\n    if (_2084)\n    {\n        _2091 = _2072 > _1282.fa_shadow_split.x;\n    }\n    else\n    {\n        _2091 = _2084;\n    }\n    if (_2091)\n    {\n        ci = 1;\n    }\n    bool _2095 = _2057 > 2;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2072 > _1282.fa_shadow_split.y;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 2;\n    }\n    bool _2106 = _2057 > 3;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2072 > _1282.fa_shadow_split.z;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2057)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2139 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n        s = _2139;\n        if (_2139 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1282.fa_shadow_cfg.y > 0.0)\n    {\n        float _2164;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2164 = fa_shadow_split_at(param_5, _1282);\n        }\n        else\n        {\n            _2164 = _1282.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2183 = _1282.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1282) - _2164, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2194 = fast::clamp((_2072 - (fa_shadow_split_at(param_7, _1282) - _2183)) / _2183, 0.0, 1.0);\n        if (_2194 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2057)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2215 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex);\n                s2 = _2215;\n                if (_2215 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2194);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex)\n{\n    bool _1688 = _542.fa_pbr.z < 0.5;\n    bool _1696;\n    if (!_1688)\n    {\n        _1696 = _1282.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1696 = _1688;\n    }\n    if (_1696)\n    {\n        return 1.0;\n    }\n    int param = (int(_1282.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1709 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1710 = _1709.x;\n    if (_1710 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1719 = int(_1710 + 0.5);\n    int param_1 = _1719;\n    float4 _1723 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1719 + 1;\n    float4 _1728 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1731 = _1723.y;\n    if (_1731 > 0.0)\n    {\n        float _1748 = 1.0 - smoothstep(0.75 * _1731, _1731, length(world - _1282.fa_shadow_eye.xyz));\n        fade = _1748;\n        if (_1748 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1723.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1767 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1770 = abs(_1767);\n        float _1772 = _1770.x;\n        float _1774 = _1770.y;\n        bool _1775 = _1772 >= _1774;\n        bool _1783;\n        if (_1775)\n        {\n            _1783 = _1772 >= _1770.z;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        int _1784;\n        if (_1783)\n        {\n            _1784 = (_1767.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1797;\n            if (_1774 >= _1770.z)\n            {\n                _1797 = (_1767.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1797 = (_1767.z > 0.0) ? 4 : 5;\n            }\n            _1784 = _1797;\n        }\n        face = _1784;\n    }\n    int _1816 = (_1719 + 2) + (face * 6);\n    int param_4 = _1816;\n    int param_5 = _1816 + 1;\n    int param_6 = _1816 + 3;\n    float4 _1830 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1816 + 4;\n    float4 _1835 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1816 + 5;\n    float4 _1840 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1852 = _1840.x * fast::max(dot(_1830, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1857 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1880 = fast::clamp(dot(n, _1830.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1903 = fast::min(sqrt(1.0 - (_1880 * _1880)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1830, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1906 = _1728.y;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1852;\n    }\n    float4 _1928 = float4(world + (n * (_1908 * sqrt(1.0 - (_1857 * _1857)))), 1.0);\n    float _1932 = dot(_1830, _1928);\n    float _1935 = _1840.y;\n    if (_1932 < _1935)\n    {\n        return 1.0;\n    }\n    float2 _1950 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1928), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1928)) / float2(_1932);\n    float _1952 = _1950.x;\n    bool _1955 = _1952 < _1835.x;\n    bool _1964;\n    if (!_1955)\n    {\n        _1964 = _1952 > _1835.z;\n    }\n    else\n    {\n        _1964 = _1955;\n    }\n    bool _1973;\n    if (!_1964)\n    {\n        _1973 = _1950.y < _1835.y;\n    }\n    else\n    {\n        _1973 = _1964;\n    }\n    bool _1982;\n    if (!_1973)\n    {\n        _1982 = _1950.y > _1835.w;\n    }\n    else\n    {\n        _1982 = _1973;\n    }\n    if (_1982)\n    {\n        return 1.0;\n    }\n    float _1988 = _1728.x;\n    float _1990;\n    if (_1988 > 0.0)\n    {\n        _1990 = _1988;\n    }\n    else\n    {\n        _1990 = 1.5 * _1852;\n    }\n    float2 param_10 = _1950;\n    float4 param_11 = _1835;\n    float param_12 = _1932 - (_1990 * (1.0 + (0.5 * _1903)));\n    float param_13 = _1852;\n    float param_14 = 1.0;\n    float param_15 = _1840.z * 0.25;\n    float param_16 = (_1852 * fast::min(_1903, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1935, _1840.z);\n    int param_18 = int(_1723.z + 0.5);\n    float param_19 = _1723.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1282, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _542, thread float4& gl_FragCoord, constant fa_shadows& _1282, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3430 = fa_lm.z > 0.5;\n    bool _3436;\n    if (_3430)\n    {\n        int param = li;\n        _3436 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3436 = _3430;\n    }\n    if (_3436)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3458 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4768 = _3458.direction;\n    float3 _4763 = _3458.color;\n    float _4770 = _3458.attenuation;\n    float _4765 = _3458.shadow;\n    int _4773 = _3458.type;\n    if ((_4773 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4768;\n        float _3472 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex, fa_world_pos);\n        _4765 = _3472;\n        _4763 *= _3472;\n    }\n    else\n    {\n        bool _3483 = _4773 != 0;\n        bool _3489;\n        if (_3483)\n        {\n            _3489 = _4770 > 0.0;\n        }\n        else\n        {\n            _3489 = _3483;\n        }\n        if (_3489)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4768;\n            float _3501 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex);\n            _4765 = _3501;\n            _4763 *= _3501;\n        }\n    }\n    return LightSample{ _4768, _4763, _4770, _4765, _3458._distance, _4773 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3047 = tdh / at;\n    float _3051 = bdh / ab;\n    float _3063 = ((_3047 * _3047) + (_3051 * _3051)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3063) * _3063);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3144 = 1.0 / alpha;\n    return ((2.0 + _3144) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3144)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3176 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3255 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3255) * _3255);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3176);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3176));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3328 = fast::max(dot(L.nc, l), 0.0);\n        float _3334 = fast::max(dot(L.nc, h), 0.0);\n        float _3343 = ((_3334 * _3334) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3343) * _3343)) * (0.5 / fast::max(mix((2.0 * _3328) * L.coat_ndv, _3328 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3328)) * _3328);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2445 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2448 = _2445.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2448 * _2448, exp2((-9.27999973297119140625) * ndv)) * _2448) + _2445.y)) + _2445.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_542.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _542.fa_env_horizon.w)).xyz;\n    }\n    float _2351 = rough * rough;\n    float _2381 = 0.60000002384185791015625 * _2351;\n    return mix(mix(_542.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_542.fa_env_horizon.xyz, _542.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2351)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2381, 0.0500000007450580596923828125 + _2381, d.y))), ((_542.fa_env_sky.xyz + _542.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2351 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2930;\n        if (L.aniso >= 0.0)\n        {\n            _2930 = L.b;\n        }\n        else\n        {\n            _2930 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2930, v), _2930), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2963 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _542, fa_env_smp, fa_env_tex) * ((f0 * _2963.x) + (float3(L.f90) * _2963.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _542, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3018 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _542, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3018.x) + _3018.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _542, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2487 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _542, fa_env_smp, fa_env_tex) * ((f0 * _2487.x) + float3(_2487.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1282)\n{\n    if (_1282.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2239 = int(_1282.fa_shadow_cfg.x + 0.5);\n    float _2249 = dot(world - _1282.fa_shadow_eye.xyz, _1282.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2254 = _2239 > 0;\n    bool _2263;\n    if (_2254)\n    {\n        int param = _2239 - 1;\n        _2263 = _2249 <= fa_shadow_split_at(param, _1282);\n    }\n    else\n    {\n        _2263 = _2254;\n    }\n    if (_2263)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2270 = _2239 > 1;\n        bool _2277;\n        if (_2270)\n        {\n            _2277 = _2249 > _1282.fa_shadow_split.x;\n        }\n        else\n        {\n            _2277 = _2270;\n        }\n        if (_2277)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2283 = _2239 > 2;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2249 > _1282.fa_shadow_split.y;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2296 = _2239 > 3;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2249 > _1282.fa_shadow_split.z;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _542 [[buffer(1)]], constant fa_material& _3526 [[buffer(5)]], constant fa_shadows& _1282 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4485 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4485 = -_4485;\n    }\n    float3 _3910 = fast::normalize(_542.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _542, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n    Surface _3918 = fa_standard_surface(param_1, _542, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4516 = _3918.albedo;\n    float _4517 = _3918.alpha;\n    float3 _4518 = _3918.normal;\n    float _4519 = _3918.metallic;\n    float _4520 = _3918.roughness;\n    float _4521 = _3918.occlusion;\n    float3 _4522 = _3918.emission;\n    float _4523 = _3918.clearcoat;\n    float _4524 = _3918.clearcoat_roughness;\n    float3 _4525 = _3918.sheen_color;\n    float _4526 = _3918.sheen_roughness;\n    float _4527 = _3918.anisotropy;\n    float _4528 = _3918.anisotropy_rotation;\n    float _4529 = _3918.specular;\n    float _4530 = _3918.ior;\n    float3 _4531 = _3918.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n    Surface param_3 = _3918;\n    surface(param_2, param_3, tint, _3526);\n    _4516 = param_3.albedo;\n    _4517 = param_3.alpha;\n    _4518 = param_3.normal;\n    _4519 = param_3.metallic;\n    _4520 = param_3.roughness;\n    _4521 = param_3.occlusion;\n    _4522 = param_3.emission;\n    _4523 = param_3.clearcoat;\n    _4524 = param_3.clearcoat_roughness;\n    _4525 = param_3.sheen_color;\n    _4526 = param_3.sheen_roughness;\n    _4527 = param_3.anisotropy;\n    _4528 = param_3.anisotropy_rotation;\n    _4529 = param_3.specular;\n    _4530 = param_3.ior;\n    _4531 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4485;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _542, fa_decal_tex, fa_env_smp);\n    _4516 = param_6;\n    _4518 = param_7;\n    float3 result;\n    if (_542.fa_emissive.w > 0.5)\n    {\n        result = _4516;\n    }\n    else\n    {\n        float3 _3957 = fast::normalize(_4518);\n        float _3964 = fast::clamp(_4519, 0.0, 1.0);\n        float _3968 = fast::clamp(_4520, 0.0500000007450580596923828125, 1.0);\n        float _3972 = _3968 * _3968;\n        float _3976 = _3972 * _3972;\n        float _3981 = fast::max(dot(_3957, _3910), 9.9999997473787516355514526367188e-05);\n        float3 _3987 = _4516 * (1.0 - _3964);\n        float3 _3994 = mix(float3(0.039999999105930328369140625), _4516, float3(_3964));\n        float3 f0 = _3994;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4485, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3910, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4516, _4517, _4518, _4519, _4520, _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531 };\n        float3 param_10 = _3957;\n        float3 param_11 = _3910;\n        float param_12 = _3964;\n        float param_13 = _3968;\n        float3 param_14 = _3994;\n        FaLayers _4010 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3957;\n        float3 lit = (fa_indirect_diffuse(param_15, _542, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3987) * _4521;\n        if (_4010.on)\n        {\n            lit *= _4010.base_scale;\n        }\n        int _4032 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4032; ln++)\n        {\n            int param_16 = ln;\n            int _4045 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _542, fa_cl_ndir, fa_cl_slot);\n            bool _4048 = in.fa_lm.z > 0.5;\n            bool _4054;\n            if (_4048)\n            {\n                int param_17 = _4045;\n                _4054 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4054 = _4048;\n            }\n            if (_4054)\n            {\n                continue;\n            }\n            int param_18 = _4045;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4485;\n            LightSample _4066 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _542, gl_FragCoord, _1282, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4690 = _4066.direction;\n            float _4074 = fast::max(dot(_3957, _4690), 0.0);\n            float _4080 = _4066.attenuation * _4066.shadow;\n            float3 _4085 = fast::normalize(_4690 + _3910);\n            float _4090 = fast::max(dot(_3957, _4085), 0.0);\n            float _4095 = fast::max(dot(_3910, _4085), 0.0);\n            if (_4010.on)\n            {\n                FaLayers param_21 = _4010;\n                float3 param_22 = _3987;\n                float3 param_23 = f0;\n                float3 param_24 = _3957;\n                float3 param_25 = _3910;\n                float3 param_26 = _4690;\n                float3 param_27 = _4085;\n                float param_28 = _4074;\n                float param_29 = _3981;\n                float param_30 = _4090;\n                float param_31 = _4095;\n                float param_32 = _3972;\n                float param_33 = _3976;\n                int param_34 = _4045;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4080));\n            }\n            else\n            {\n                float _4143 = ((_4090 * _4090) * (_3976 - 1.0)) + 1.0;\n                int param_35 = _4045;\n                lit += (((_3987 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4095, 5.0))) * (((_3976 / ((3.1415927410125732421875 * _4143) * _4143)) * (0.5 / fast::max(mix((2.0 * _4074) * _3981, _4074 + _3981, _3972), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4074))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4074 * _4080));\n            }\n        }\n        if (_4010.on)\n        {\n            FaLayers param_36 = _4010;\n            float3 param_37 = _3957;\n            float3 param_38 = _3910;\n            float3 param_39 = f0;\n            float param_40 = _3968;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _542, fa_env_smp, fa_env_tex) * _4521);\n        }\n        else\n        {\n            float3 param_41 = _3957;\n            float3 param_42 = _3910;\n            float3 param_43 = f0;\n            float param_44 = _3968;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _542, fa_env_smp, fa_env_tex) * _4521);\n        }\n        result = lit;\n    }\n    float3 _4236 = result;\n    float3 _4237 = _4236 + _4522;\n    result = _4237;\n    float3 param_45 = _4237;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1282);\n    bool _4246 = _542.fa_fog.w > 0.0;\n    bool _4253;\n    if (!_4246)\n    {\n        _4253 = _542.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4253 = _4246;\n    }\n    if (_4253)\n    {\n        float3 _4262 = in.fa_world_pos - _542.fa_camera_pos.xyz;\n        float _4268 = dot(_4262, _542.fa_fog_c.xyz);\n        bool _4272 = _542.fa_fog_c.w > 0.5;\n        float _4273;\n        if (_4272)\n        {\n            _4273 = _4268;\n        }\n        else\n        {\n            _4273 = length(_4262);\n        }\n        float _4285 = _4273 - _542.fa_fog_b.x;\n        if (_4285 > 0.0)\n        {\n            float _4294 = _542.fa_fog.w * _4285;\n            float tau = _4294 * _4294;\n            if (_542.fa_fog_b.y > 0.0)\n            {\n                float _4310;\n                if (_4272)\n                {\n                    _4310 = in.fa_world_pos.y - (_542.fa_fog_c.y * _4268);\n                }\n                else\n                {\n                    _4310 = _542.fa_camera_pos.y;\n                }\n                float _4331 = mix(_4310, in.fa_world_pos.y, fast::clamp(_542.fa_fog_b.x / _4273, 0.0, 1.0));\n                float _4335 = in.fa_world_pos.y - _4331;\n                float _4340 = _4331 - _542.fa_fog_b.z;\n                float _4345 = in.fa_world_pos.y - _542.fa_fog_b.z;\n                bool _4348 = _4340 <= 0.0;\n                bool _4349 = !_4348;\n                bool _4355;\n                if (_4349)\n                {\n                    _4355 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4355 = _4348;\n                }\n                float _4356;\n                if (_4355)\n                {\n                    _4356 = _542.fa_fog_b.y;\n                }\n                else\n                {\n                    _4356 = _542.fa_fog_b.y * exp(-fast::min(_542.fa_fog_b.w * _4340, 80.0));\n                }\n                bool _4383;\n                if (_4349)\n                {\n                    _4383 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4383 = _4348;\n                }\n                float _4384;\n                if (_4383)\n                {\n                    _4384 = _542.fa_fog_b.y * _4340;\n                }\n                else\n                {\n                    _4384 = (_542.fa_fog_b.y * (1.0 - exp(-fast::min(_542.fa_fog_b.w * _4340, 80.0)))) / _542.fa_fog_b.w;\n                }\n                bool _4409 = _4345 <= 0.0;\n                bool _4416;\n                if (!_4409)\n                {\n                    _4416 = _542.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4416 = _4409;\n                }\n                float _4417;\n                if (_4416)\n                {\n                    _4417 = _542.fa_fog_b.y * _4345;\n                }\n                else\n                {\n                    _4417 = (_542.fa_fog_b.y * (1.0 - exp(-fast::min(_542.fa_fog_b.w * _4345, 80.0)))) / _542.fa_fog_b.w;\n                }\n                float _4444;\n                if (abs(_4335) < 0.001000000047497451305389404296875)\n                {\n                    _4444 = _4356;\n                }\n                else\n                {\n                    _4444 = (_4417 - _4384) / _4335;\n                }\n                tau += (_4285 * fast::max(_4444, 0.0));\n            }\n            result = mix(result, _542.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4517);\n    return out;\n}\n\n",
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
            "inst_name": "_542",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1282",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3526",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    float4 _280 = (_771 * _253.fa_base_color) * i.vertex_color;\n    float3 _734 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = _253.fa_layers_a.x;\n    float _740 = _253.fa_layers_a.y;\n    float _743 = _253.fa_layers_a.z;\n    float _742 = _253.fa_layers_b.w;\n    float _745 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _734, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _739, _740, _253.fa_layers_b.xyz, _742, _743, _253.fa_layers_a.w, _745, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _645 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _645, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _645, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    float4 _280 = (_771 * _253.fa_base_color) * i.vertex_color;\n    float3 _734 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = _253.fa_layers_a.x;\n    float _740 = _253.fa_layers_a.y;\n    float _743 = _253.fa_layers_a.z;\n    float _742 = _253.fa_layers_b.w;\n    float _745 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _734, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _739, _740, _253.fa_layers_b.xyz, _742, _743, _253.fa_layers_a.w, _745, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _645 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _645, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _645, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
