{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _153.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _1991 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _869 = _387.fa_cl_info.x < 0.0;\n    bool _876;\n    if (!_869)\n    {\n        _876 = _387.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _876 = _869;\n    }\n    bool _884;\n    if (!_876)\n    {\n        _884 = _387.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _884 = _876;\n    }\n    bool _891;\n    if (!_884)\n    {\n        _891 = _387.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _891 = _884;\n    }\n    bool _898;\n    if (!_891)\n    {\n        _898 = _387.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _898 = _891;\n    }\n    if (_898)\n    {\n        return int2(0);\n    }\n    float4 _908 = float4(world_pos, 1.0);\n    float _915 = dot(_387.fa_cl_vpw, _908);\n    if (!(_915 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _937 = float2(dot(_387.fa_cl_vpx, _908), dot(_387.fa_cl_vpy, _908)) / float2(_915);\n    int _941 = int(_387.fa_cl_grid.x);\n    int _945 = int(_387.fa_cl_grid.y);\n    int param = (int(_387.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_387.fa_cl_fwd.xyz, world_pos) + _387.fa_cl_fwd.w, _387.fa_cl_grid.w) / _387.fa_cl_grid.w) * _387.fa_cl_grid.z)), 0, int(_387.fa_cl_info.y) - 1) * _945) + clamp(int(floor(((_937.y * 0.5) + 0.5) * _387.fa_cl_grid.y)), 0, _945 - 1)) * _941)) + clamp(int(floor(((_937.x * 0.5) + 0.5) * _387.fa_cl_grid.x)), 0, _941 - 1);\n    float4 _1016 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1016.x), int(_1016.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_387.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2808 = fa_cluster_lookup(param, _387, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2808.x;\n    fa_cl_local = _2808.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3753 = fa_linear_to_srgb(param);\n        c = _3753;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3761 = fa_srgb_to_linear(param_1);\n            c = _3761;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _319;\n    if (bool(i.front_facing))\n    {\n        _319 = i.world_normal;\n    }\n    else\n    {\n        _319 = -i.world_normal;\n    }\n    float3 _343 = fast::normalize(i.world_tangent.xyz - (_319 * dot(_319, i.world_tangent.xyz)));\n    float3 _371 = fast::normalize(((_343 * m.x) + ((cross(_319, _343) * i.world_tangent.w) * m.y)) + (_319 * m.z));\n    float3 _374;\n    if (bool(i.front_facing))\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _387, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _387.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3792 = fa_tex_fix(param_2, param_3);\n    float4 _5022 = base_t;\n    _5022.x = _3792.x;\n    _5022.y = _3792.y;\n    _5022.z = _3792.z;\n    base_t = _5022;\n    float4 _3806 = (_5022 * _387.fa_base_color) * i.vertex_color;\n    float3 _4932 = i.world_normal;\n    if (_387.fa_maps.z > 0.5)\n    {\n        float param_4 = _387.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3838 = fa_tex_fix(param_6, param_7);\n        float3 _3841 = (_3838 * 2.0) - float3(1.0);\n        float2 _3846 = _3841.xy * _387.fa_maps.x;\n        float3 _5030 = _3841;\n        _5030.x = _3846.x;\n        _5030.y = _3846.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5030;\n        _4932 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _387.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3874 = fa_tex_fix(param_12, param_13);\n    float4 _5033 = mrt;\n    _5033.x = _3874.x;\n    _5033.y = _3874.y;\n    _5033.z = _3874.z;\n    mrt = _5033;\n    float4 _3902 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _387.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3902.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3914 = fa_tex_fix(param_16, param_17);\n    float param_18 = _387.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3944 = fa_tex_fix(param_20, param_21);\n    float _4937 = _387.fa_layers_a.x;\n    float _4938 = _387.fa_layers_a.y;\n    float _4941 = _387.fa_layers_a.z;\n    float _4940 = _387.fa_layers_b.w;\n    float _4943 = _387.fa_layers_c.x;\n    if (_387.fa_layers_c.z > 0.5)\n    {\n        if (mod(_387.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4937 *= _3914.y;\n            _4938 *= _3914.z;\n            _4940 *= _3902.w;\n        }\n        if (_387.fa_layers_c.z > 1.5)\n        {\n            _4941 *= mrt.x;\n            _4943 *= mrt.w;\n        }\n    }\n    return Surface{ _3806.xyz, _3806.w, _4932, fast::clamp(_387.fa_pbr.x * _3874.z, 0.0, 1.0), fast::clamp(_387.fa_pbr.y * _3874.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_387.fa_maps.y * (_3914.x - 1.0)), _387.fa_emissive.xyz + (_387.fa_model_emissive.xyz * _3944), _4937, _4938, _387.fa_layers_b.xyz, _4940, _4941, _387.fa_layers_a.w, _4943, _387.fa_layers_c.y, _387.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3689)\n{\n    s.emission += ((tint.xyz * tint.w) * _3689.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1916 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1924 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1927 = int(_1916);\n    int _1930 = int(_1924);\n    float _1940 = _1924 - float(_1930);\n    int _1996 = (_1927 * 9) + _1930;\n    int _2016 = ((_1927 + 1) * 9) + _1930;\n    return mix(mix(_1991[_1996], _1991[_1996 + 1], _1940), mix(_1991[_2016], _1991[_2016 + 1], _1940), _1916 - float(_1927));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4868 = false;\n    float _4869 = 1.0;\n    float _4870 = 1.0;\n    float _4871 = 1.0;\n    float _4872 = 0.0;\n    float _4873 = 0.0;\n    float _4874 = 0.0;\n    float _4875 = 0.0;\n    float _4877 = 1.0;\n    bool _4878 = false;\n    float3 _4879 = float3(0.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _4882 = 1.0;\n    float _4883 = 0.0;\n    float _4884 = 0.0;\n    float3 _4885 = float3(1.0, 0.0, 0.0);\n    float3 _4886 = float3(0.0, 0.0, 1.0);\n    float _4887 = 1.0;\n    float _4888 = 1.0;\n    float _2070 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2074 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2079 = (_2070 != 1.0) || (_2074 != 1.5);\n    bool _2088;\n    if (!_2079)\n    {\n        _2088 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2088 = _2079;\n    }\n    if (_2088)\n    {\n        float _2096 = (_2074 - 1.0) / (_2074 + 1.0);\n        f0 = mix(fast::min(float3(_2096 * _2096) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2070, s.albedo, float3(metallic));\n        _4869 = mix(_2070, 1.0, metallic);\n        _4868 = true;\n    }\n    float _2124 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2124 > 0.0)\n    {\n        float _2132 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4872 = _2124;\n        _4873 = _2132;\n        float _2139 = _2132 * _2132;\n        _4874 = _2139;\n        _4875 = _2139 * _2139;\n        float _2151 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4877 = _2151;\n        _4870 = 1.0 - (_2124 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2151, 0.0, 1.0), 5.0))));\n        _4868 = true;\n    }\n    float3 _2171 = fast::max(s.sheen_color, float3(0.0));\n    float _2180 = fast::max(_2171.x, fast::max(_2171.y, _2171.z));\n    if (_2180 > 0.0)\n    {\n        float _2188 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4878 = true;\n        _4879 = _2171;\n        _4880 = _2188;\n        _4881 = _2188 * _2188;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2188;\n        float _2205 = fa_sheen_albedo(param, param_1);\n        _4883 = _2205;\n        _4882 = 1.0 - fast::min(_2180 * _2205, 1.0);\n        _4868 = true;\n    }\n    _4871 = _4870 * _4882;\n    float _2224 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2224 != 0.0)\n    {\n        float3 _2239 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2239;\n        if (dot(_2239, _2239) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2257 = t;\n        float3 _2258 = fast::normalize(_2257);\n        t = _2258;\n        float3 _2283 = fast::normalize((_2258 * cos(s.anisotropy_rotation)) + ((cross(n, _2258) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4885 = _2283;\n        _4886 = cross(n, _2283);\n        float _2293 = roughness * roughness;\n        float _2299 = mix(_2293, 1.0, _2224 * _2224);\n        bool _2301 = _2224 > 0.0;\n        _4887 = _2301 ? _2299 : _2293;\n        _4888 = _2301 ? _2293 : _2299;\n        _4884 = _2224;\n        _4868 = true;\n    }\n    return FaLayers{ short(_4868), _4869, _4870, _4871, _4872, _4873, _4874, _4875, i.world_normal, _4877, short(_4878), _4879, _4880, _4881, _4882, _4883, _4884, _4885, _4886, _4887, _4888 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_387.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _387.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_387.fa_cl_info.x) + int(_387.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _387, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _387)\n{\n    return li * ((_387.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _477 = dot(d, right);\n    float _481 = dot(d, up);\n    float _492;\n    if (((_477 * _477) + (_481 * _481)) > 1.0000000133514319600180897396058e-10)\n    {\n        _492 = precise::atan2(_481, _477) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_492 - floor(_492)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _525 = fa_light_base(param, _387);\n    bool _529 = _387.fa_counts.y > 4.5;\n    int param_1 = _525;\n    float4 _533 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _525 + 1;\n    float4 _538 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _541 = _538.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _553 = _529 && (_541 > 2.5);\n    fa_light_is_area = _553;\n    bool _556 = _541 < 0.5;\n    float3 l;\n    if (_556)\n    {\n        l = fast::normalize(_533.xyz);\n        if (_529)\n        {\n            int param_3 = _525 + 6;\n            float4 _570 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_570.z > 0.5)\n            {\n                int param_4 = _525 + 4;\n                float4 _580 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _525 + 5;\n                float4 _586 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _570.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _580.xyz) * _580.w, (-dot(world_pos, _586.xyz)) * _586.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _618 = _533.xyz - world_pos;\n        float _620 = length(_618);\n        dist = _620;\n        l = _618 / float3(fast::max(_620, 9.9999997473787516355514526367188e-05));\n        float reach = _620;\n        if (_553)\n        {\n            int param_8 = _525 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _652 = reach / fast::max(_533.w, 0.001000000047497451305389404296875);\n        float _658 = fast::clamp(1.0 - (_652 * _652), 0.0, 1.0);\n        atten = _658 * _658;\n        bool _666 = _541 < 2.5;\n        if ((_541 > 1.5) && _666)\n        {\n            int param_9 = _525 + 2;\n            float4 _674 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _684 = _674.w;\n            int param_10 = _525 + 3;\n            float4 _690 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _691 = _690.x;\n            float cos_inner = _691;\n            if (_691 > 1.5)\n            {\n                cos_inner = mix(_684, 1.0, 0.25);\n            }\n            atten *= smoothstep(_684, cos_inner, dot(-l, fast::normalize(_674.xyz)));\n        }\n        if (_529 && _666)\n        {\n            int param_11 = _525 + 6;\n            float4 _715 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _525 + 7;\n            float4 _720 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _723 = _715.z > 0.5;\n            bool _730;\n            if (!_723)\n            {\n                _730 = _720.z > 0.5;\n            }\n            else\n            {\n                _730 = _723;\n            }\n            if (_730)\n            {\n                int param_13 = _525 + 2;\n                float4 _737 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _741 = fast::normalize(_737.xyz);\n                int param_14 = _525 + 4;\n                float4 _746 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _525 + 5;\n                float4 _751 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_723)\n                {\n                    float3 _759 = -_618;\n                    float _766 = _737.w;\n                    float _782 = 0.5 / fast::max(dot(_759, _741) * (sqrt(fast::max(1.0 - (_766 * _766), 0.0)) / fast::max(_766, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _715.xy;\n                    float2 param_17 = float2(0.5 + (dot(_759, _746.xyz) * _782), 0.5 - (dot(_759, _751.xyz) * _782));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_720.z > 0.5)\n                {\n                    float2 param_18 = _720.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _741;\n                    float3 param_21 = _746.xyz;\n                    float3 param_22 = _751.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _4856 = _538.xyz * atten;\n    if (_529)\n    {\n        _4856 *= fa_light_tint;\n    }\n    int _851;\n    if (_556)\n    {\n        _851 = 0;\n    }\n    else\n    {\n        _851 = ((_541 > 1.5) && (_541 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4856, atten, 1.0, dist, _851 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1100)\n{\n    float _1090;\n    if (i == 0)\n    {\n        _1090 = _1100.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1106;\n        if (i == 1)\n        {\n            _1106 = _1100.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1114;\n            if (i == 2)\n            {\n                _1114 = _1100.fa_shadow_split.z;\n            }\n            else\n            {\n                _1114 = _1100.fa_shadow_split.w;\n            }\n            _1106 = _1114;\n        }\n        _1090 = _1106;\n    }\n    return _1090;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1078 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1078), sin(_1078)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex)\n{\n    float _1152 = fast::max(_1100.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1157 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1163 = sqrt(1.0 - (_1157 * _1157));\n    float _1171 = fast::min(_1163 / fast::max(_1157, 0.20000000298023223876953125), 4.0);\n    float _1176;\n    if (_1100.fa_shadow_bias.y > 0.0)\n    {\n        _1176 = _1100.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1176 = 1.5 * _1100.fa_shadow_info[ci].x;\n    }\n    float4 _1201 = _1100.fa_shadow_mat[ci] * float4(world + (n * (_1176 * _1163)), 1.0);\n    float _1208 = _1201.x;\n    bool _1211 = _1208 < _1100.fa_shadow_rect[ci].x;\n    bool _1220;\n    if (!_1211)\n    {\n        _1220 = _1208 > _1100.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1220 = _1211;\n    }\n    bool _1229;\n    if (!_1220)\n    {\n        _1229 = _1201.y < _1100.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1229 = _1220;\n    }\n    bool _1238;\n    if (!_1229)\n    {\n        _1238 = _1201.y > _1100.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1238 = _1229;\n    }\n    bool _1245;\n    if (!_1238)\n    {\n        _1245 = _1201.z > 1.0;\n    }\n    else\n    {\n        _1245 = _1238;\n    }\n    if (_1245)\n    {\n        return -1.0;\n    }\n    float _1253;\n    if (_1100.fa_shadow_bias.x > 0.0)\n    {\n        _1253 = _1100.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1253 = 1.5 * _1100.fa_shadow_info[ci].x;\n    }\n    float _1272 = _1201.z - ((_1253 * (1.0 + (0.5 * _1171))) / _1152);\n    float _1281 = ((_1100.fa_shadow_info[ci].x * fast::min(_1171, 3.0)) * 0.5) / _1152;\n    int _1290 = int(_1100.fa_shadow_cfg.z + 0.5);\n    if (_1290 == 1)\n    {\n        float2 param = _1201.xy;\n        float4 param_1 = _1100.fa_shadow_rect[ci];\n        float _1301 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1272 <= _1301);\n    }\n    float _1308 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1311 = _1290 == 2;\n    if (_1311)\n    {\n        float _1325 = fast::clamp(((_1100.fa_shadow_cfg.w * _1152) * 0.25) / _1100.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1308;\n            float2 _1344 = fa_shadow_vogel(param_2, param_3, param_4) * _1325;\n            float2 param_5 = _1201.xy + (_1344 * _1100.fa_shadow_bias.zw);\n            float4 param_6 = _1100.fa_shadow_rect[ci];\n            float _1355 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1355 < (_1272 - (length(_1344) * _1281)))\n            {\n                sum += _1355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1272 - (sum / cnt), 0.0) * _1152) * _1100.fa_shadow_cfg.w) / _1100.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1399 = _1311 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1399; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1399;\n        float param_9 = _1308;\n        float2 _1418 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1201.xy + (_1418 * _1100.fa_shadow_bias.zw);\n        float4 param_11 = _1100.fa_shadow_rect[ci];\n        float _1429 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1272 - (length(_1418) * _1281)) <= _1429);\n    }\n    return lit / float(_1399);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _387, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex)\n{\n    if (_387.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1459 = int(_1100.fa_shadow_cfg.x + 0.5);\n    if (_1459 < 1)\n    {\n        return 1.0;\n    }\n    float _1474 = dot(world - _1100.fa_shadow_eye.xyz, _1100.fa_shadow_fwd.xyz);\n    int param = _1459 - 1;\n    if (_1474 > fa_shadow_split_at(param, _1100))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1486 = _1459 > 1;\n    bool _1493;\n    if (_1486)\n    {\n        _1493 = _1474 > _1100.fa_shadow_split.x;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    if (_1493)\n    {\n        ci = 1;\n    }\n    bool _1497 = _1459 > 2;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1474 > _1100.fa_shadow_split.y;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 2;\n    }\n    bool _1508 = _1459 > 3;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1474 > _1100.fa_shadow_split.z;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1459)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1541 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n        s = _1541;\n        if (_1541 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1100.fa_shadow_cfg.y > 0.0)\n    {\n        float _1566;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1566 = fa_shadow_split_at(param_5, _1100);\n        }\n        else\n        {\n            _1566 = _1100.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1585 = _1100.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1100) - _1566, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1596 = fast::clamp((_1474 - (fa_shadow_split_at(param_7, _1100) - _1585)) / _1585, 0.0, 1.0);\n        if (_1596 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1459)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1617 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n                s2 = _1617;\n                if (_1617 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1596);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _387, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _387, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2836 = fa_light_sample(param, param_1, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4912 = _2836.color;\n    float _4914 = _2836.shadow;\n    if ((_2836.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2836.direction;\n        float _2850 = fa_shadow_factor(param_2, param_3, _387, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex, fa_world_pos);\n        _4914 = _2850;\n        _4912 *= _2850;\n    }\n    return LightSample{ _2836.direction, _4912, _2836.attenuation, _4914, _2836._distance, _2836.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _2890 = v - (n * dot(v, n));\n    float3 t = _2890;\n    float _2894 = dot(_2890, _2890);\n    float l2 = _2894;\n    if (_2894 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _2904;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2904 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2904 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _2904;\n        l2 = dot(_2904, _2904);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _2939 = dot(a, a);\n    float _2943 = dot(b, b);\n    if ((_2939 < 1.0000000195414813782625560981111e-24) || (_2943 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _2957 = a * rsqrt(_2939);\n    float3 _2962 = b * rsqrt(_2943);\n    float _2966 = dot(_2957, _2962);\n    float _2969 = abs(_2966);\n    float g = (((((((((((0.0416471660137176513671875 * _2969) - 0.1924748718738555908203125) * _2969) + 0.4179156124591827392578125) * _2969) - 0.616057217121124267578125) * _2969) + 0.777722418308258056640625) * _2969) - 0.999542415142059326171875) * _2969) + 1.570791721343994140625;\n    if (_2966 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_2966 * _2966), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2957, _2962) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _3026 = a.z > 0.0;\n    bool _3030 = b.z > 0.0;\n    if (_3026 && _3030)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3026 != _3030)\n        {\n            float3 _3065 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3065.z = 0.0;\n            if (_3026)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3065;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3065;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _3065;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3065;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _3114 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3140 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3166 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3192 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _3114;\n    float3 param_1 = _3140;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3140;\n    float3 param_7 = _3166;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3166;\n    float3 param_13 = _3192;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3192;\n    float3 param_19 = _3114;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3342 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3366 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3382 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _3342;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _3366;\n    float4 param_9 = m;\n    float3 param_10 = _3342;\n    float3 param_11 = _3366;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _3382;\n    float4 param_14 = m;\n    float3 param_15 = _3342;\n    float3 param_16 = _3382;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _3440 = fa_light_base(param, _387);\n    int param_1 = _3440;\n    int param_2 = _3440 + 1;\n    int param_3 = _3440 + 2;\n    int param_4 = _3440 + 4;\n    float4 _3462 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _3440 + 5;\n    float4 _3467 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _3440 + 6;\n    float4 _3472 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _3473 = _3472.w;\n    float3 _3478 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _3480 = _3473 < 1.5;\n    bool _3487;\n    if (_3480)\n    {\n        _3487 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _3478) >= 0.0;\n    }\n    else\n    {\n        _3487 = _3480;\n    }\n    if (_3487)\n    {\n        return float3(0.0);\n    }\n    bool _3496 = (_3473 > 0.5) && _3480;\n    float _3500 = _3496 ? 1.0539000034332275390625 : 1.0;\n    float3 _3503 = _3462.xyz;\n    float _3505 = _3462.w;\n    float3 _3511 = _3467.xyz;\n    float _3513 = _3467.w;\n    float3 up = _3511 * (_3513 * _3500);\n    float _3519;\n    if (_3496)\n    {\n        _3519 = (3.1415927410125732421875 * _3505) * _3505;\n    }\n    else\n    {\n        _3519 = (4.0 * _3505) * _3513;\n    }\n    if (_3473 > 1.5)\n    {\n        float3 _3545 = cross(_3503, -_3478);\n        float3 perp = _3545;\n        float _3549 = dot(_3545, _3545);\n        float3 _3552;\n        if (_3549 > 1.0000000133514319600180897396058e-10)\n        {\n            _3552 = perp * rsqrt(_3549);\n        }\n        else\n        {\n            _3552 = _3511;\n        }\n        perp = _3552;\n        up = _3552 * _3513;\n    }\n    float _3573 = fast::max(_3519, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3583 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3583;\n    float3 param_10 = n;\n    float3 param_11 = _3478;\n    float3 _3591 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3583;\n    float3 param_13 = n;\n    float3 param_14 = _3503 * (_3505 * _3500);\n    float3 _3599 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3583;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3607 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3473;\n    float3 param_20 = _3591;\n    float3 param_21 = _3599;\n    float3 param_22 = _3607;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3626 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _3626;\n    float2 param_26 = _3626 + float2(64.0, 0.0);\n    float4 _3636 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _3473;\n    float3 param_29 = _3591;\n    float3 param_30 = _3599;\n    float3 param_31 = _3607;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3636.x) + ((float3(1.0) - f0) * _3636.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_3478, _3478)) + _3573) / _3573) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2451 = tdh / at;\n    float _2455 = bdh / ab;\n    float _2467 = ((_2451 * _2451) + (_2455 * _2455)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2467) * _2467);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2548 = 1.0 / alpha;\n    return ((2.0 + _2548) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2548)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2581 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2660 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2660) * _2660);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2581);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2581));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2733 = fast::max(dot(L.nc, l), 0.0);\n        float _2739 = fast::max(dot(L.nc, h), 0.0);\n        float _2748 = ((_2739 * _2739) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2748) * _2748)) * (0.5 / fast::max(mix((2.0 * _2733) * L.coat_ndv, _2733 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2733)) * _2733);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _387) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1848 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1851 = _1848.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1851 * _1851, exp2((-9.27999973297119140625) * ndv)) * _1851) + _1848.y)) + _1848.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_387.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _387.fa_env_horizon.w)).xyz;\n    }\n    float _1753 = rough * rough;\n    float _1783 = 0.60000002384185791015625 * _1753;\n    return mix(mix(_387.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_387.fa_env_horizon.xyz, _387.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1753)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1783, 0.0500000007450580596923828125 + _1783, d.y))), ((_387.fa_env_sky.xyz + _387.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1753 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2334;\n        if (L.aniso >= 0.0)\n        {\n            _2334 = L.b;\n        }\n        else\n        {\n            _2334 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2334, v), _2334), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2367 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _387, fa_env_smp, fa_env_tex) * ((f0 * _2367.x) + (float3(L.f90) * _2367.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _387, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2422 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _387, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2422.x) + _2422.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1890 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _387, fa_env_smp, fa_env_tex) * ((f0 * _1890.x) + float3(_1890.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1100)\n{\n    if (_1100.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1641 = int(_1100.fa_shadow_cfg.x + 0.5);\n    float _1651 = dot(world - _1100.fa_shadow_eye.xyz, _1100.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1656 = _1641 > 0;\n    bool _1665;\n    if (_1656)\n    {\n        int param = _1641 - 1;\n        _1665 = _1651 <= fa_shadow_split_at(param, _1100);\n    }\n    else\n    {\n        _1665 = _1656;\n    }\n    if (_1665)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1672 = _1641 > 1;\n        bool _1679;\n        if (_1672)\n        {\n            _1679 = _1651 > _1100.fa_shadow_split.x;\n        }\n        else\n        {\n            _1679 = _1672;\n        }\n        if (_1679)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1685 = _1641 > 2;\n        bool _1692;\n        if (_1685)\n        {\n            _1692 = _1651 > _1100.fa_shadow_split.y;\n        }\n        else\n        {\n            _1692 = _1685;\n        }\n        if (_1692)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1698 = _1641 > 3;\n        bool _1705;\n        if (_1698)\n        {\n            _1705 = _1651 > _1100.fa_shadow_split.z;\n        }\n        else\n        {\n            _1705 = _1698;\n        }\n        if (_1705)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _387 [[buffer(1)]], constant fa_material& _3689 [[buffer(5)]], constant fa_shadows& _1100 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4647 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4647 = -_4647;\n    }\n    float3 _4065 = fast::normalize(_387.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _387, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface _4073 = fa_standard_surface(param_1, _387, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4678 = _4073.albedo;\n    float _4679 = _4073.alpha;\n    float3 _4680 = _4073.normal;\n    float _4681 = _4073.metallic;\n    float _4682 = _4073.roughness;\n    float _4683 = _4073.occlusion;\n    float3 _4684 = _4073.emission;\n    float _4685 = _4073.clearcoat;\n    float _4686 = _4073.clearcoat_roughness;\n    float3 _4687 = _4073.sheen_color;\n    float _4688 = _4073.sheen_roughness;\n    float _4689 = _4073.anisotropy;\n    float _4690 = _4073.anisotropy_rotation;\n    float _4691 = _4073.specular;\n    float _4692 = _4073.ior;\n    float3 _4693 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface param_3 = _4073;\n    surface(param_2, param_3, tint, _3689);\n    _4678 = param_3.albedo;\n    _4679 = param_3.alpha;\n    _4680 = param_3.normal;\n    _4681 = param_3.metallic;\n    _4682 = param_3.roughness;\n    _4683 = param_3.occlusion;\n    _4684 = param_3.emission;\n    _4685 = param_3.clearcoat;\n    _4686 = param_3.clearcoat_roughness;\n    _4687 = param_3.sheen_color;\n    _4688 = param_3.sheen_roughness;\n    _4689 = param_3.anisotropy;\n    _4690 = param_3.anisotropy_rotation;\n    _4691 = param_3.specular;\n    _4692 = param_3.ior;\n    _4693 = param_3.specular_color;\n    float3 result;\n    if (_387.fa_emissive.w > 0.5)\n    {\n        result = _4678;\n    }\n    else\n    {\n        float3 _4095 = fast::normalize(_4680);\n        float _4102 = fast::clamp(_4681, 0.0, 1.0);\n        float _4106 = fast::clamp(_4682, 0.0500000007450580596923828125, 1.0);\n        float _4110 = _4106 * _4106;\n        float _4114 = _4110 * _4110;\n        float _4119 = fast::max(dot(_4095, _4065), 9.9999997473787516355514526367188e-05);\n        float3 _4125 = _4678 * (1.0 - _4102);\n        float3 _4132 = mix(float3(0.039999999105930328369140625), _4678, float3(_4102));\n        float3 f0 = _4132;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693 };\n        float3 param_6 = _4095;\n        float3 param_7 = _4065;\n        float param_8 = _4102;\n        float param_9 = _4106;\n        float3 param_10 = _4132;\n        FaLayers _4148 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4095;\n        float3 lit = (fa_ambient_light(param_11, _387, fa_env_smp, fa_irr_tex) * _4125) * _4683;\n        if (_4148.on)\n        {\n            lit *= _4148.base_scale;\n        }\n        int _4170 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4170; ln++)\n        {\n            int param_12 = ln;\n            int _4183 = fa_cl_light(param_12, _387, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4183;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _4647;\n            LightSample _4192 = fa_light_shadowed(param_13, param_14, param_15, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _1100, fa_shadow_tex, in.fa_world_pos);\n            float _4200 = fast::max(dot(_4095, _4192.direction), 0.0);\n            float _4206 = _4192.attenuation * _4192.shadow;\n            float3 _4211 = fast::normalize(_4192.direction + _4065);\n            float _4216 = fast::max(dot(_4095, _4211), 0.0);\n            float _4221 = fast::max(dot(_4065, _4211), 0.0);\n            bool _4228;\n            if (fa_light_is_area)\n            {\n                _4228 = !_4148.on;\n            }\n            else\n            {\n                _4228 = fa_light_is_area;\n            }\n            if (_4228)\n            {\n                int param_16 = _4183;\n                float3 param_17 = in.fa_world_pos;\n                float3 param_18 = _4095;\n                float3 param_19 = _4065;\n                float3 param_20 = _4125;\n                float3 param_21 = f0;\n                float param_22 = _4106;\n                float param_23 = _4119;\n                float param_24 = _4206;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (_4148.on)\n                {\n                    FaLayers param_25 = _4148;\n                    float3 param_26 = _4125;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4095;\n                    float3 param_29 = _4065;\n                    float3 param_30 = _4192.direction;\n                    float3 param_31 = _4211;\n                    float param_32 = _4200;\n                    float param_33 = _4119;\n                    float param_34 = _4216;\n                    float param_35 = _4221;\n                    float param_36 = _4110;\n                    float param_37 = _4114;\n                    int param_38 = _4183;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38, _387, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _4206));\n                }\n                else\n                {\n                    float _4303 = ((_4216 * _4216) * (_4114 - 1.0)) + 1.0;\n                    int param_39 = _4183;\n                    lit += (((_4125 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4221, 5.0))) * (((_4114 / ((3.1415927410125732421875 * _4303) * _4303)) * (0.5 / fast::max(mix((2.0 * _4200) * _4119, _4200 + _4119, _4110), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4200))) * (fa_light_rgb(param_39, _387, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_4200 * _4206));\n                }\n            }\n        }\n        if (_4148.on)\n        {\n            FaLayers param_40 = _4148;\n            float3 param_41 = _4095;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4106;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44, _387, fa_env_smp, fa_env_tex) * _4683);\n        }\n        else\n        {\n            float3 param_45 = _4095;\n            float3 param_46 = _4065;\n            float3 param_47 = f0;\n            float param_48 = _4106;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48, _387, fa_env_smp, fa_env_tex) * _4683);\n        }\n        result = lit;\n    }\n    float3 _4398 = result;\n    float3 _4399 = _4398 + _4684;\n    result = _4399;\n    float3 param_49 = _4399;\n    float3 param_50 = in.fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50, _1100);\n    bool _4408 = _387.fa_fog.w > 0.0;\n    bool _4415;\n    if (!_4408)\n    {\n        _4415 = _387.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4415 = _4408;\n    }\n    if (_4415)\n    {\n        float3 _4424 = in.fa_world_pos - _387.fa_camera_pos.xyz;\n        float _4430 = dot(_4424, _387.fa_fog_c.xyz);\n        bool _4434 = _387.fa_fog_c.w > 0.5;\n        float _4435;\n        if (_4434)\n        {\n            _4435 = _4430;\n        }\n        else\n        {\n            _4435 = length(_4424);\n        }\n        float _4447 = _4435 - _387.fa_fog_b.x;\n        if (_4447 > 0.0)\n        {\n            float _4456 = _387.fa_fog.w * _4447;\n            float tau = _4456 * _4456;\n            if (_387.fa_fog_b.y > 0.0)\n            {\n                float _4472;\n                if (_4434)\n                {\n                    _4472 = in.fa_world_pos.y - (_387.fa_fog_c.y * _4430);\n                }\n                else\n                {\n                    _4472 = _387.fa_camera_pos.y;\n                }\n                float _4493 = mix(_4472, in.fa_world_pos.y, fast::clamp(_387.fa_fog_b.x / _4435, 0.0, 1.0));\n                float _4497 = in.fa_world_pos.y - _4493;\n                float _4502 = _4493 - _387.fa_fog_b.z;\n                float _4507 = in.fa_world_pos.y - _387.fa_fog_b.z;\n                bool _4510 = _4502 <= 0.0;\n                bool _4511 = !_4510;\n                bool _4517;\n                if (_4511)\n                {\n                    _4517 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4510;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = _387.fa_fog_b.y;\n                }\n                else\n                {\n                    _4518 = _387.fa_fog_b.y * exp(-fast::min(_387.fa_fog_b.w * _4502, 80.0));\n                }\n                bool _4545;\n                if (_4511)\n                {\n                    _4545 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4545 = _4510;\n                }\n                float _4546;\n                if (_4545)\n                {\n                    _4546 = _387.fa_fog_b.y * _4502;\n                }\n                else\n                {\n                    _4546 = (_387.fa_fog_b.y * (1.0 - exp(-fast::min(_387.fa_fog_b.w * _4502, 80.0)))) / _387.fa_fog_b.w;\n                }\n                bool _4571 = _4507 <= 0.0;\n                bool _4578;\n                if (!_4571)\n                {\n                    _4578 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4578 = _4571;\n                }\n                float _4579;\n                if (_4578)\n                {\n                    _4579 = _387.fa_fog_b.y * _4507;\n                }\n                else\n                {\n                    _4579 = (_387.fa_fog_b.y * (1.0 - exp(-fast::min(_387.fa_fog_b.w * _4507, 80.0)))) / _387.fa_fog_b.w;\n                }\n                float _4606;\n                if (abs(_4497) < 0.001000000047497451305389404296875)\n                {\n                    _4606 = _4518;\n                }\n                else\n                {\n                    _4606 = (_4579 - _4546) / _4497;\n                }\n                tau += (_4447 * fast::max(_4606, 0.0));\n            }\n            result = mix(result, _387.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4679);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_387",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1100",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3689",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _1991 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _869 = _387.fa_cl_info.x < 0.0;\n    bool _876;\n    if (!_869)\n    {\n        _876 = _387.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _876 = _869;\n    }\n    bool _884;\n    if (!_876)\n    {\n        _884 = _387.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _884 = _876;\n    }\n    bool _891;\n    if (!_884)\n    {\n        _891 = _387.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _891 = _884;\n    }\n    bool _898;\n    if (!_891)\n    {\n        _898 = _387.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _898 = _891;\n    }\n    if (_898)\n    {\n        return int2(0);\n    }\n    float4 _908 = float4(world_pos, 1.0);\n    float _915 = dot(_387.fa_cl_vpw, _908);\n    if (!(_915 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _937 = float2(dot(_387.fa_cl_vpx, _908), dot(_387.fa_cl_vpy, _908)) / float2(_915);\n    int _941 = int(_387.fa_cl_grid.x);\n    int _945 = int(_387.fa_cl_grid.y);\n    int param = (int(_387.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_387.fa_cl_fwd.xyz, world_pos) + _387.fa_cl_fwd.w, _387.fa_cl_grid.w) / _387.fa_cl_grid.w) * _387.fa_cl_grid.z)), 0, int(_387.fa_cl_info.y) - 1) * _945) + clamp(int(floor(((_937.y * 0.5) + 0.5) * _387.fa_cl_grid.y)), 0, _945 - 1)) * _941)) + clamp(int(floor(((_937.x * 0.5) + 0.5) * _387.fa_cl_grid.x)), 0, _941 - 1);\n    float4 _1016 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1016.x), int(_1016.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_387.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2808 = fa_cluster_lookup(param, _387, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2808.x;\n    fa_cl_local = _2808.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3753 = fa_linear_to_srgb(param);\n        c = _3753;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3761 = fa_srgb_to_linear(param_1);\n            c = _3761;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _319;\n    if (bool(i.front_facing))\n    {\n        _319 = i.world_normal;\n    }\n    else\n    {\n        _319 = -i.world_normal;\n    }\n    float3 _343 = fast::normalize(i.world_tangent.xyz - (_319 * dot(_319, i.world_tangent.xyz)));\n    float3 _371 = fast::normalize(((_343 * m.x) + ((cross(_319, _343) * i.world_tangent.w) * m.y)) + (_319 * m.z));\n    float3 _374;\n    if (bool(i.front_facing))\n    {\n        _374 = _371;\n    }\n    else\n    {\n        _374 = -_371;\n    }\n    return _374;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _387, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _387.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3792 = fa_tex_fix(param_2, param_3);\n    float4 _5022 = base_t;\n    _5022.x = _3792.x;\n    _5022.y = _3792.y;\n    _5022.z = _3792.z;\n    base_t = _5022;\n    float4 _3806 = (_5022 * _387.fa_base_color) * i.vertex_color;\n    float3 _4932 = i.world_normal;\n    if (_387.fa_maps.z > 0.5)\n    {\n        float param_4 = _387.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3838 = fa_tex_fix(param_6, param_7);\n        float3 _3841 = (_3838 * 2.0) - float3(1.0);\n        float2 _3846 = _3841.xy * _387.fa_maps.x;\n        float3 _5030 = _3841;\n        _5030.x = _3846.x;\n        _5030.y = _3846.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5030;\n        _4932 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _387.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3874 = fa_tex_fix(param_12, param_13);\n    float4 _5033 = mrt;\n    _5033.x = _3874.x;\n    _5033.y = _3874.y;\n    _5033.z = _3874.z;\n    mrt = _5033;\n    float4 _3902 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _387.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3902.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3914 = fa_tex_fix(param_16, param_17);\n    float param_18 = _387.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3944 = fa_tex_fix(param_20, param_21);\n    float _4937 = _387.fa_layers_a.x;\n    float _4938 = _387.fa_layers_a.y;\n    float _4941 = _387.fa_layers_a.z;\n    float _4940 = _387.fa_layers_b.w;\n    float _4943 = _387.fa_layers_c.x;\n    if (_387.fa_layers_c.z > 0.5)\n    {\n        if (mod(_387.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4937 *= _3914.y;\n            _4938 *= _3914.z;\n            _4940 *= _3902.w;\n        }\n        if (_387.fa_layers_c.z > 1.5)\n        {\n            _4941 *= mrt.x;\n            _4943 *= mrt.w;\n        }\n    }\n    return Surface{ _3806.xyz, _3806.w, _4932, fast::clamp(_387.fa_pbr.x * _3874.z, 0.0, 1.0), fast::clamp(_387.fa_pbr.y * _3874.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_387.fa_maps.y * (_3914.x - 1.0)), _387.fa_emissive.xyz + (_387.fa_model_emissive.xyz * _3944), _4937, _4938, _387.fa_layers_b.xyz, _4940, _4941, _387.fa_layers_a.w, _4943, _387.fa_layers_c.y, _387.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3689)\n{\n    s.emission += ((tint.xyz * tint.w) * _3689.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1916 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1924 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1927 = int(_1916);\n    int _1930 = int(_1924);\n    float _1940 = _1924 - float(_1930);\n    int _1996 = (_1927 * 9) + _1930;\n    int _2016 = ((_1927 + 1) * 9) + _1930;\n    return mix(mix(_1991[_1996], _1991[_1996 + 1], _1940), mix(_1991[_2016], _1991[_2016 + 1], _1940), _1916 - float(_1927));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4868 = false;\n    float _4869 = 1.0;\n    float _4870 = 1.0;\n    float _4871 = 1.0;\n    float _4872 = 0.0;\n    float _4873 = 0.0;\n    float _4874 = 0.0;\n    float _4875 = 0.0;\n    float _4877 = 1.0;\n    bool _4878 = false;\n    float3 _4879 = float3(0.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _4882 = 1.0;\n    float _4883 = 0.0;\n    float _4884 = 0.0;\n    float3 _4885 = float3(1.0, 0.0, 0.0);\n    float3 _4886 = float3(0.0, 0.0, 1.0);\n    float _4887 = 1.0;\n    float _4888 = 1.0;\n    float _2070 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2074 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2079 = (_2070 != 1.0) || (_2074 != 1.5);\n    bool _2088;\n    if (!_2079)\n    {\n        _2088 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2088 = _2079;\n    }\n    if (_2088)\n    {\n        float _2096 = (_2074 - 1.0) / (_2074 + 1.0);\n        f0 = mix(fast::min(float3(_2096 * _2096) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2070, s.albedo, float3(metallic));\n        _4869 = mix(_2070, 1.0, metallic);\n        _4868 = true;\n    }\n    float _2124 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2124 > 0.0)\n    {\n        float _2132 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4872 = _2124;\n        _4873 = _2132;\n        float _2139 = _2132 * _2132;\n        _4874 = _2139;\n        _4875 = _2139 * _2139;\n        float _2151 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4877 = _2151;\n        _4870 = 1.0 - (_2124 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2151, 0.0, 1.0), 5.0))));\n        _4868 = true;\n    }\n    float3 _2171 = fast::max(s.sheen_color, float3(0.0));\n    float _2180 = fast::max(_2171.x, fast::max(_2171.y, _2171.z));\n    if (_2180 > 0.0)\n    {\n        float _2188 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4878 = true;\n        _4879 = _2171;\n        _4880 = _2188;\n        _4881 = _2188 * _2188;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2188;\n        float _2205 = fa_sheen_albedo(param, param_1);\n        _4883 = _2205;\n        _4882 = 1.0 - fast::min(_2180 * _2205, 1.0);\n        _4868 = true;\n    }\n    _4871 = _4870 * _4882;\n    float _2224 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2224 != 0.0)\n    {\n        float3 _2239 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2239;\n        if (dot(_2239, _2239) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2257 = t;\n        float3 _2258 = fast::normalize(_2257);\n        t = _2258;\n        float3 _2283 = fast::normalize((_2258 * cos(s.anisotropy_rotation)) + ((cross(n, _2258) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4885 = _2283;\n        _4886 = cross(n, _2283);\n        float _2293 = roughness * roughness;\n        float _2299 = mix(_2293, 1.0, _2224 * _2224);\n        bool _2301 = _2224 > 0.0;\n        _4887 = _2301 ? _2299 : _2293;\n        _4888 = _2301 ? _2293 : _2299;\n        _4884 = _2224;\n        _4868 = true;\n    }\n    return FaLayers{ short(_4868), _4869, _4870, _4871, _4872, _4873, _4874, _4875, i.world_normal, _4877, short(_4878), _4879, _4880, _4881, _4882, _4883, _4884, _4885, _4886, _4887, _4888 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_387.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _387.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_387.fa_cl_info.x) + int(_387.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _387, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _387)\n{\n    return li * ((_387.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _477 = dot(d, right);\n    float _481 = dot(d, up);\n    float _492;\n    if (((_477 * _477) + (_481 * _481)) > 1.0000000133514319600180897396058e-10)\n    {\n        _492 = precise::atan2(_481, _477) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_492 - floor(_492)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _525 = fa_light_base(param, _387);\n    bool _529 = _387.fa_counts.y > 4.5;\n    int param_1 = _525;\n    float4 _533 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _525 + 1;\n    float4 _538 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _541 = _538.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _553 = _529 && (_541 > 2.5);\n    fa_light_is_area = _553;\n    bool _556 = _541 < 0.5;\n    float3 l;\n    if (_556)\n    {\n        l = fast::normalize(_533.xyz);\n        if (_529)\n        {\n            int param_3 = _525 + 6;\n            float4 _570 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_570.z > 0.5)\n            {\n                int param_4 = _525 + 4;\n                float4 _580 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _525 + 5;\n                float4 _586 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _570.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _580.xyz) * _580.w, (-dot(world_pos, _586.xyz)) * _586.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _618 = _533.xyz - world_pos;\n        float _620 = length(_618);\n        dist = _620;\n        l = _618 / float3(fast::max(_620, 9.9999997473787516355514526367188e-05));\n        float reach = _620;\n        if (_553)\n        {\n            int param_8 = _525 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _652 = reach / fast::max(_533.w, 0.001000000047497451305389404296875);\n        float _658 = fast::clamp(1.0 - (_652 * _652), 0.0, 1.0);\n        atten = _658 * _658;\n        bool _666 = _541 < 2.5;\n        if ((_541 > 1.5) && _666)\n        {\n            int param_9 = _525 + 2;\n            float4 _674 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _684 = _674.w;\n            int param_10 = _525 + 3;\n            float4 _690 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _691 = _690.x;\n            float cos_inner = _691;\n            if (_691 > 1.5)\n            {\n                cos_inner = mix(_684, 1.0, 0.25);\n            }\n            atten *= smoothstep(_684, cos_inner, dot(-l, fast::normalize(_674.xyz)));\n        }\n        if (_529 && _666)\n        {\n            int param_11 = _525 + 6;\n            float4 _715 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _525 + 7;\n            float4 _720 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _723 = _715.z > 0.5;\n            bool _730;\n            if (!_723)\n            {\n                _730 = _720.z > 0.5;\n            }\n            else\n            {\n                _730 = _723;\n            }\n            if (_730)\n            {\n                int param_13 = _525 + 2;\n                float4 _737 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _741 = fast::normalize(_737.xyz);\n                int param_14 = _525 + 4;\n                float4 _746 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _525 + 5;\n                float4 _751 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_723)\n                {\n                    float3 _759 = -_618;\n                    float _766 = _737.w;\n                    float _782 = 0.5 / fast::max(dot(_759, _741) * (sqrt(fast::max(1.0 - (_766 * _766), 0.0)) / fast::max(_766, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _715.xy;\n                    float2 param_17 = float2(0.5 + (dot(_759, _746.xyz) * _782), 0.5 - (dot(_759, _751.xyz) * _782));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_720.z > 0.5)\n                {\n                    float2 param_18 = _720.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _741;\n                    float3 param_21 = _746.xyz;\n                    float3 param_22 = _751.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _4856 = _538.xyz * atten;\n    if (_529)\n    {\n        _4856 *= fa_light_tint;\n    }\n    int _851;\n    if (_556)\n    {\n        _851 = 0;\n    }\n    else\n    {\n        _851 = ((_541 > 1.5) && (_541 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4856, atten, 1.0, dist, _851 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1100)\n{\n    float _1090;\n    if (i == 0)\n    {\n        _1090 = _1100.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1106;\n        if (i == 1)\n        {\n            _1106 = _1100.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1114;\n            if (i == 2)\n            {\n                _1114 = _1100.fa_shadow_split.z;\n            }\n            else\n            {\n                _1114 = _1100.fa_shadow_split.w;\n            }\n            _1106 = _1114;\n        }\n        _1090 = _1106;\n    }\n    return _1090;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1078 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1078), sin(_1078)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex)\n{\n    float _1152 = fast::max(_1100.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1157 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1163 = sqrt(1.0 - (_1157 * _1157));\n    float _1171 = fast::min(_1163 / fast::max(_1157, 0.20000000298023223876953125), 4.0);\n    float _1176;\n    if (_1100.fa_shadow_bias.y > 0.0)\n    {\n        _1176 = _1100.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1176 = 1.5 * _1100.fa_shadow_info[ci].x;\n    }\n    float4 _1201 = _1100.fa_shadow_mat[ci] * float4(world + (n * (_1176 * _1163)), 1.0);\n    float _1208 = _1201.x;\n    bool _1211 = _1208 < _1100.fa_shadow_rect[ci].x;\n    bool _1220;\n    if (!_1211)\n    {\n        _1220 = _1208 > _1100.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1220 = _1211;\n    }\n    bool _1229;\n    if (!_1220)\n    {\n        _1229 = _1201.y < _1100.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1229 = _1220;\n    }\n    bool _1238;\n    if (!_1229)\n    {\n        _1238 = _1201.y > _1100.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1238 = _1229;\n    }\n    bool _1245;\n    if (!_1238)\n    {\n        _1245 = _1201.z > 1.0;\n    }\n    else\n    {\n        _1245 = _1238;\n    }\n    if (_1245)\n    {\n        return -1.0;\n    }\n    float _1253;\n    if (_1100.fa_shadow_bias.x > 0.0)\n    {\n        _1253 = _1100.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1253 = 1.5 * _1100.fa_shadow_info[ci].x;\n    }\n    float _1272 = _1201.z - ((_1253 * (1.0 + (0.5 * _1171))) / _1152);\n    float _1281 = ((_1100.fa_shadow_info[ci].x * fast::min(_1171, 3.0)) * 0.5) / _1152;\n    int _1290 = int(_1100.fa_shadow_cfg.z + 0.5);\n    if (_1290 == 1)\n    {\n        float2 param = _1201.xy;\n        float4 param_1 = _1100.fa_shadow_rect[ci];\n        float _1301 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1272 <= _1301);\n    }\n    float _1308 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1311 = _1290 == 2;\n    if (_1311)\n    {\n        float _1325 = fast::clamp(((_1100.fa_shadow_cfg.w * _1152) * 0.25) / _1100.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1308;\n            float2 _1344 = fa_shadow_vogel(param_2, param_3, param_4) * _1325;\n            float2 param_5 = _1201.xy + (_1344 * _1100.fa_shadow_bias.zw);\n            float4 param_6 = _1100.fa_shadow_rect[ci];\n            float _1355 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1355 < (_1272 - (length(_1344) * _1281)))\n            {\n                sum += _1355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1272 - (sum / cnt), 0.0) * _1152) * _1100.fa_shadow_cfg.w) / _1100.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1399 = _1311 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1399; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1399;\n        float param_9 = _1308;\n        float2 _1418 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1201.xy + (_1418 * _1100.fa_shadow_bias.zw);\n        float4 param_11 = _1100.fa_shadow_rect[ci];\n        float _1429 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1272 - (length(_1418) * _1281)) <= _1429);\n    }\n    return lit / float(_1399);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _387, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex)\n{\n    if (_387.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1459 = int(_1100.fa_shadow_cfg.x + 0.5);\n    if (_1459 < 1)\n    {\n        return 1.0;\n    }\n    float _1474 = dot(world - _1100.fa_shadow_eye.xyz, _1100.fa_shadow_fwd.xyz);\n    int param = _1459 - 1;\n    if (_1474 > fa_shadow_split_at(param, _1100))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1486 = _1459 > 1;\n    bool _1493;\n    if (_1486)\n    {\n        _1493 = _1474 > _1100.fa_shadow_split.x;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    if (_1493)\n    {\n        ci = 1;\n    }\n    bool _1497 = _1459 > 2;\n    bool _1504;\n    if (_1497)\n    {\n        _1504 = _1474 > _1100.fa_shadow_split.y;\n    }\n    else\n    {\n        _1504 = _1497;\n    }\n    if (_1504)\n    {\n        ci = 2;\n    }\n    bool _1508 = _1459 > 3;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1474 > _1100.fa_shadow_split.z;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1459)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1541 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n        s = _1541;\n        if (_1541 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1100.fa_shadow_cfg.y > 0.0)\n    {\n        float _1566;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1566 = fa_shadow_split_at(param_5, _1100);\n        }\n        else\n        {\n            _1566 = _1100.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1585 = _1100.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1100) - _1566, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1596 = fast::clamp((_1474 - (fa_shadow_split_at(param_7, _1100) - _1585)) / _1585, 0.0, 1.0);\n        if (_1596 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1459)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1617 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n                s2 = _1617;\n                if (_1617 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1596);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _387, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _387, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _1100, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2836 = fa_light_sample(param, param_1, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4912 = _2836.color;\n    float _4914 = _2836.shadow;\n    if ((_2836.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2836.direction;\n        float _2850 = fa_shadow_factor(param_2, param_3, _387, fa_shadow_smp, gl_FragCoord, _1100, fa_shadow_tex, fa_world_pos);\n        _4914 = _2850;\n        _4912 *= _2850;\n    }\n    return LightSample{ _2836.direction, _4912, _2836.attenuation, _4914, _2836._distance, _2836.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _2890 = v - (n * dot(v, n));\n    float3 t = _2890;\n    float _2894 = dot(_2890, _2890);\n    float l2 = _2894;\n    if (_2894 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _2904;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2904 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2904 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _2904;\n        l2 = dot(_2904, _2904);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _2939 = dot(a, a);\n    float _2943 = dot(b, b);\n    if ((_2939 < 1.0000000195414813782625560981111e-24) || (_2943 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _2957 = a * rsqrt(_2939);\n    float3 _2962 = b * rsqrt(_2943);\n    float _2966 = dot(_2957, _2962);\n    float _2969 = abs(_2966);\n    float g = (((((((((((0.0416471660137176513671875 * _2969) - 0.1924748718738555908203125) * _2969) + 0.4179156124591827392578125) * _2969) - 0.616057217121124267578125) * _2969) + 0.777722418308258056640625) * _2969) - 0.999542415142059326171875) * _2969) + 1.570791721343994140625;\n    if (_2966 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_2966 * _2966), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2957, _2962) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _3026 = a.z > 0.0;\n    bool _3030 = b.z > 0.0;\n    if (_3026 && _3030)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3026 != _3030)\n        {\n            float3 _3065 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3065.z = 0.0;\n            if (_3026)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3065;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3065;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _3065;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3065;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _3114 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3140 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3166 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3192 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _3114;\n    float3 param_1 = _3140;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3140;\n    float3 param_7 = _3166;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3166;\n    float3 param_13 = _3192;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3192;\n    float3 param_19 = _3114;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3342 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3366 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3382 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _3342;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _3366;\n    float4 param_9 = m;\n    float3 param_10 = _3342;\n    float3 param_11 = _3366;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _3382;\n    float4 param_14 = m;\n    float3 param_15 = _3342;\n    float3 param_16 = _3382;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _3440 = fa_light_base(param, _387);\n    int param_1 = _3440;\n    int param_2 = _3440 + 1;\n    int param_3 = _3440 + 2;\n    int param_4 = _3440 + 4;\n    float4 _3462 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _3440 + 5;\n    float4 _3467 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _3440 + 6;\n    float4 _3472 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _3473 = _3472.w;\n    float3 _3478 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _3480 = _3473 < 1.5;\n    bool _3487;\n    if (_3480)\n    {\n        _3487 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _3478) >= 0.0;\n    }\n    else\n    {\n        _3487 = _3480;\n    }\n    if (_3487)\n    {\n        return float3(0.0);\n    }\n    bool _3496 = (_3473 > 0.5) && _3480;\n    float _3500 = _3496 ? 1.0539000034332275390625 : 1.0;\n    float3 _3503 = _3462.xyz;\n    float _3505 = _3462.w;\n    float3 _3511 = _3467.xyz;\n    float _3513 = _3467.w;\n    float3 up = _3511 * (_3513 * _3500);\n    float _3519;\n    if (_3496)\n    {\n        _3519 = (3.1415927410125732421875 * _3505) * _3505;\n    }\n    else\n    {\n        _3519 = (4.0 * _3505) * _3513;\n    }\n    if (_3473 > 1.5)\n    {\n        float3 _3545 = cross(_3503, -_3478);\n        float3 perp = _3545;\n        float _3549 = dot(_3545, _3545);\n        float3 _3552;\n        if (_3549 > 1.0000000133514319600180897396058e-10)\n        {\n            _3552 = perp * rsqrt(_3549);\n        }\n        else\n        {\n            _3552 = _3511;\n        }\n        perp = _3552;\n        up = _3552 * _3513;\n    }\n    float _3573 = fast::max(_3519, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3583 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3583;\n    float3 param_10 = n;\n    float3 param_11 = _3478;\n    float3 _3591 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3583;\n    float3 param_13 = n;\n    float3 param_14 = _3503 * (_3505 * _3500);\n    float3 _3599 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3583;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3607 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3473;\n    float3 param_20 = _3591;\n    float3 param_21 = _3599;\n    float3 param_22 = _3607;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3626 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _3626;\n    float2 param_26 = _3626 + float2(64.0, 0.0);\n    float4 _3636 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _3473;\n    float3 param_29 = _3591;\n    float3 param_30 = _3599;\n    float3 param_31 = _3607;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3636.x) + ((float3(1.0) - f0) * _3636.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_3478, _3478)) + _3573) / _3573) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2451 = tdh / at;\n    float _2455 = bdh / ab;\n    float _2467 = ((_2451 * _2451) + (_2455 * _2455)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2467) * _2467);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2548 = 1.0 / alpha;\n    return ((2.0 + _2548) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2548)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2581 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2660 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2660) * _2660);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2581);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2581));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2733 = fast::max(dot(L.nc, l), 0.0);\n        float _2739 = fast::max(dot(L.nc, h), 0.0);\n        float _2748 = ((_2739 * _2739) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2748) * _2748)) * (0.5 / fast::max(mix((2.0 * _2733) * L.coat_ndv, _2733 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2733)) * _2733);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _387, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _387) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1848 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1851 = _1848.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1851 * _1851, exp2((-9.27999973297119140625) * ndv)) * _1851) + _1848.y)) + _1848.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_387.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _387.fa_env_horizon.w)).xyz;\n    }\n    float _1753 = rough * rough;\n    float _1783 = 0.60000002384185791015625 * _1753;\n    return mix(mix(_387.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_387.fa_env_horizon.xyz, _387.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1753)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1783, 0.0500000007450580596923828125 + _1783, d.y))), ((_387.fa_env_sky.xyz + _387.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1753 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2334;\n        if (L.aniso >= 0.0)\n        {\n            _2334 = L.b;\n        }\n        else\n        {\n            _2334 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2334, v), _2334), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2367 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _387, fa_env_smp, fa_env_tex) * ((f0 * _2367.x) + (float3(L.f90) * _2367.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _387, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2422 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _387, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2422.x) + _2422.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _387, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1890 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _387, fa_env_smp, fa_env_tex) * ((f0 * _1890.x) + float3(_1890.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1100)\n{\n    if (_1100.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1641 = int(_1100.fa_shadow_cfg.x + 0.5);\n    float _1651 = dot(world - _1100.fa_shadow_eye.xyz, _1100.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1656 = _1641 > 0;\n    bool _1665;\n    if (_1656)\n    {\n        int param = _1641 - 1;\n        _1665 = _1651 <= fa_shadow_split_at(param, _1100);\n    }\n    else\n    {\n        _1665 = _1656;\n    }\n    if (_1665)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1672 = _1641 > 1;\n        bool _1679;\n        if (_1672)\n        {\n            _1679 = _1651 > _1100.fa_shadow_split.x;\n        }\n        else\n        {\n            _1679 = _1672;\n        }\n        if (_1679)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1685 = _1641 > 2;\n        bool _1692;\n        if (_1685)\n        {\n            _1692 = _1651 > _1100.fa_shadow_split.y;\n        }\n        else\n        {\n            _1692 = _1685;\n        }\n        if (_1692)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1698 = _1641 > 3;\n        bool _1705;\n        if (_1698)\n        {\n            _1705 = _1651 > _1100.fa_shadow_split.z;\n        }\n        else\n        {\n            _1705 = _1698;\n        }\n        if (_1705)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _387 [[buffer(1)]], constant fa_material& _3689 [[buffer(5)]], constant fa_shadows& _1100 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _4647 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4647 = -_4647;\n    }\n    float3 _4065 = fast::normalize(_387.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _387, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface _4073 = fa_standard_surface(param_1, _387, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4678 = _4073.albedo;\n    float _4679 = _4073.alpha;\n    float3 _4680 = _4073.normal;\n    float _4681 = _4073.metallic;\n    float _4682 = _4073.roughness;\n    float _4683 = _4073.occlusion;\n    float3 _4684 = _4073.emission;\n    float _4685 = _4073.clearcoat;\n    float _4686 = _4073.clearcoat_roughness;\n    float3 _4687 = _4073.sheen_color;\n    float _4688 = _4073.sheen_roughness;\n    float _4689 = _4073.anisotropy;\n    float _4690 = _4073.anisotropy_rotation;\n    float _4691 = _4073.specular;\n    float _4692 = _4073.ior;\n    float3 _4693 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n    Surface param_3 = _4073;\n    surface(param_2, param_3, tint, _3689);\n    _4678 = param_3.albedo;\n    _4679 = param_3.alpha;\n    _4680 = param_3.normal;\n    _4681 = param_3.metallic;\n    _4682 = param_3.roughness;\n    _4683 = param_3.occlusion;\n    _4684 = param_3.emission;\n    _4685 = param_3.clearcoat;\n    _4686 = param_3.clearcoat_roughness;\n    _4687 = param_3.sheen_color;\n    _4688 = param_3.sheen_roughness;\n    _4689 = param_3.anisotropy;\n    _4690 = param_3.anisotropy_rotation;\n    _4691 = param_3.specular;\n    _4692 = param_3.ior;\n    _4693 = param_3.specular_color;\n    float3 result;\n    if (_387.fa_emissive.w > 0.5)\n    {\n        result = _4678;\n    }\n    else\n    {\n        float3 _4095 = fast::normalize(_4680);\n        float _4102 = fast::clamp(_4681, 0.0, 1.0);\n        float _4106 = fast::clamp(_4682, 0.0500000007450580596923828125, 1.0);\n        float _4110 = _4106 * _4106;\n        float _4114 = _4110 * _4110;\n        float _4119 = fast::max(dot(_4095, _4065), 9.9999997473787516355514526367188e-05);\n        float3 _4125 = _4678 * (1.0 - _4102);\n        float3 _4132 = mix(float3(0.039999999105930328369140625), _4678, float3(_4102));\n        float3 f0 = _4132;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _4647, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4065, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693 };\n        float3 param_6 = _4095;\n        float3 param_7 = _4065;\n        float param_8 = _4102;\n        float param_9 = _4106;\n        float3 param_10 = _4132;\n        FaLayers _4148 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4095;\n        float3 lit = (fa_ambient_light(param_11, _387, fa_env_smp, fa_irr_tex) * _4125) * _4683;\n        if (_4148.on)\n        {\n            lit *= _4148.base_scale;\n        }\n        int _4170 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4170; ln++)\n        {\n            int param_12 = ln;\n            int _4183 = fa_cl_light(param_12, _387, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4183;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _4647;\n            LightSample _4192 = fa_light_shadowed(param_13, param_14, param_15, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _1100, fa_shadow_tex, in.fa_world_pos);\n            float _4200 = fast::max(dot(_4095, _4192.direction), 0.0);\n            float _4206 = _4192.attenuation * _4192.shadow;\n            float3 _4211 = fast::normalize(_4192.direction + _4065);\n            float _4216 = fast::max(dot(_4095, _4211), 0.0);\n            float _4221 = fast::max(dot(_4065, _4211), 0.0);\n            bool _4228;\n            if (fa_light_is_area)\n            {\n                _4228 = !_4148.on;\n            }\n            else\n            {\n                _4228 = fa_light_is_area;\n            }\n            if (_4228)\n            {\n                int param_16 = _4183;\n                float3 param_17 = in.fa_world_pos;\n                float3 param_18 = _4095;\n                float3 param_19 = _4065;\n                float3 param_20 = _4125;\n                float3 param_21 = f0;\n                float param_22 = _4106;\n                float param_23 = _4119;\n                float param_24 = _4206;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, _387, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (_4148.on)\n                {\n                    FaLayers param_25 = _4148;\n                    float3 param_26 = _4125;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4095;\n                    float3 param_29 = _4065;\n                    float3 param_30 = _4192.direction;\n                    float3 param_31 = _4211;\n                    float param_32 = _4200;\n                    float param_33 = _4119;\n                    float param_34 = _4216;\n                    float param_35 = _4221;\n                    float param_36 = _4110;\n                    float param_37 = _4114;\n                    int param_38 = _4183;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38, _387, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _4206));\n                }\n                else\n                {\n                    float _4303 = ((_4216 * _4216) * (_4114 - 1.0)) + 1.0;\n                    int param_39 = _4183;\n                    lit += (((_4125 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4221, 5.0))) * (((_4114 / ((3.1415927410125732421875 * _4303) * _4303)) * (0.5 / fast::max(mix((2.0 * _4200) * _4119, _4200 + _4119, _4110), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4200))) * (fa_light_rgb(param_39, _387, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_4200 * _4206));\n                }\n            }\n        }\n        if (_4148.on)\n        {\n            FaLayers param_40 = _4148;\n            float3 param_41 = _4095;\n            float3 param_42 = _4065;\n            float3 param_43 = f0;\n            float param_44 = _4106;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44, _387, fa_env_smp, fa_env_tex) * _4683);\n        }\n        else\n        {\n            float3 param_45 = _4095;\n            float3 param_46 = _4065;\n            float3 param_47 = f0;\n            float param_48 = _4106;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48, _387, fa_env_smp, fa_env_tex) * _4683);\n        }\n        result = lit;\n    }\n    float3 _4398 = result;\n    float3 _4399 = _4398 + _4684;\n    result = _4399;\n    float3 param_49 = _4399;\n    float3 param_50 = in.fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50, _1100);\n    bool _4408 = _387.fa_fog.w > 0.0;\n    bool _4415;\n    if (!_4408)\n    {\n        _4415 = _387.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4415 = _4408;\n    }\n    if (_4415)\n    {\n        float3 _4424 = in.fa_world_pos - _387.fa_camera_pos.xyz;\n        float _4430 = dot(_4424, _387.fa_fog_c.xyz);\n        bool _4434 = _387.fa_fog_c.w > 0.5;\n        float _4435;\n        if (_4434)\n        {\n            _4435 = _4430;\n        }\n        else\n        {\n            _4435 = length(_4424);\n        }\n        float _4447 = _4435 - _387.fa_fog_b.x;\n        if (_4447 > 0.0)\n        {\n            float _4456 = _387.fa_fog.w * _4447;\n            float tau = _4456 * _4456;\n            if (_387.fa_fog_b.y > 0.0)\n            {\n                float _4472;\n                if (_4434)\n                {\n                    _4472 = in.fa_world_pos.y - (_387.fa_fog_c.y * _4430);\n                }\n                else\n                {\n                    _4472 = _387.fa_camera_pos.y;\n                }\n                float _4493 = mix(_4472, in.fa_world_pos.y, fast::clamp(_387.fa_fog_b.x / _4435, 0.0, 1.0));\n                float _4497 = in.fa_world_pos.y - _4493;\n                float _4502 = _4493 - _387.fa_fog_b.z;\n                float _4507 = in.fa_world_pos.y - _387.fa_fog_b.z;\n                bool _4510 = _4502 <= 0.0;\n                bool _4511 = !_4510;\n                bool _4517;\n                if (_4511)\n                {\n                    _4517 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4517 = _4510;\n                }\n                float _4518;\n                if (_4517)\n                {\n                    _4518 = _387.fa_fog_b.y;\n                }\n                else\n                {\n                    _4518 = _387.fa_fog_b.y * exp(-fast::min(_387.fa_fog_b.w * _4502, 80.0));\n                }\n                bool _4545;\n                if (_4511)\n                {\n                    _4545 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4545 = _4510;\n                }\n                float _4546;\n                if (_4545)\n                {\n                    _4546 = _387.fa_fog_b.y * _4502;\n                }\n                else\n                {\n                    _4546 = (_387.fa_fog_b.y * (1.0 - exp(-fast::min(_387.fa_fog_b.w * _4502, 80.0)))) / _387.fa_fog_b.w;\n                }\n                bool _4571 = _4507 <= 0.0;\n                bool _4578;\n                if (!_4571)\n                {\n                    _4578 = _387.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4578 = _4571;\n                }\n                float _4579;\n                if (_4578)\n                {\n                    _4579 = _387.fa_fog_b.y * _4507;\n                }\n                else\n                {\n                    _4579 = (_387.fa_fog_b.y * (1.0 - exp(-fast::min(_387.fa_fog_b.w * _4507, 80.0)))) / _387.fa_fog_b.w;\n                }\n                float _4606;\n                if (abs(_4497) < 0.001000000047497451305389404296875)\n                {\n                    _4606 = _4518;\n                }\n                else\n                {\n                    _4606 = (_4579 - _4546) / _4497;\n                }\n                tau += (_4447 * fast::max(_4606, 0.0));\n            }\n            result = mix(result, _387.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4679);\n    return out;\n}\n\n",
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
            "size": 160,
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
            "inst_name": "_387",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1100",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3689",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
            "size": 160,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    float4 _310 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_158.fa_light_vp * _310).z;\n    fa_pre_r0 = float3(_158.fa_light_vp[0].x, _158.fa_light_vp[1].x, _158.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158.fa_light_vp[0].y, _158.fa_light_vp[1].y, _158.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158.fa_light_vp[0].z, _158.fa_light_vp[1].z, _158.fa_light_vp[2].z);\n    gl_Position = _158.fa_view_proj * _310;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
            "size": 160,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, raise);\n    out.gl_Position = _144.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _196)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_196.fa_joint_rows[_187] * weights[i]);\n        r1 += (_196.fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196.fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _196 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _196);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _149);\n    vertex0(param_8, raise);\n    out.gl_Position = _149.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "size": 160,
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
