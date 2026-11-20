{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    bool _465 = _460.fa_cl_info.x < 0.0;\n    bool _472;\n    if (!_465)\n    {\n        _472 = _460.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _480;\n    if (!_472)\n    {\n        _480 = _460.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _480 = _472;\n    }\n    bool _487;\n    if (!_480)\n    {\n        _487 = _460.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _487 = _480;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _460.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    if (_494)\n    {\n        return float4(0.0);\n    }\n    float4 _504 = float4(world_pos, 1.0);\n    float _511 = dot(_460.fa_cl_vpw, _504);\n    if (!(_511 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _533 = float2(dot(_460.fa_cl_vpx, _504), dot(_460.fa_cl_vpy, _504)) / float2(_511);\n    int _537 = int(_460.fa_cl_grid.x);\n    int _541 = int(_460.fa_cl_grid.y);\n    int param = (int(_460.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_460.fa_cl_fwd.xyz, world_pos) + _460.fa_cl_fwd.w, _460.fa_cl_grid.w) / _460.fa_cl_grid.w) * _460.fa_cl_grid.z)), 0, int(_460.fa_cl_info.y) - 1) * _541) + clamp(int(floor(((_533.y * 0.5) + 0.5) * _460.fa_cl_grid.y)), 0, _541 - 1)) * _537)) + clamp(int(floor(((_533.x * 0.5) + 0.5) * _460.fa_cl_grid.x)), 0, _537 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    float3 param = world_pos;\n    float4 _617 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _460);\n    return int2(int(_617.x), int(_617.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_460.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2675 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _460);\n    fa_cl_slot = _2675.x;\n    fa_cl_local = _2675.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2867 = fa_linear_to_srgb(param);\n        c = _2867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2875 = fa_srgb_to_linear(param_1);\n            c = _2875;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _225;\n    if (bool(i.front_facing))\n    {\n        _225 = i.world_normal;\n    }\n    else\n    {\n        _225 = -i.world_normal;\n    }\n    float3 _249 = fast::normalize(i.world_tangent.xyz - (_225 * dot(_225, i.world_tangent.xyz)));\n    float3 _276 = fast::normalize(((_249 * m.x) + ((cross(_225, _249) * i.world_tangent.w) * m.y)) + (_225 * m.z));\n    float3 _279;\n    if (bool(i.front_facing))\n    {\n        _279 = _276;\n    }\n    else\n    {\n        _279 = -_276;\n    }\n    return _279;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _460, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _460.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2906 = fa_tex_fix(param_2, param_3);\n    float4 _3927 = base_t;\n    _3927.x = _2906.x;\n    _3927.y = _2906.y;\n    _3927.z = _2906.z;\n    base_t = _3927;\n    float4 _2920 = (_3927 * _460.fa_base_color) * i.vertex_color;\n    float3 _3794 = i.world_normal;\n    if (_460.fa_maps.z > 0.5)\n    {\n        float param_4 = _460.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2952 = fa_tex_fix(param_6, param_7);\n        float3 _2955 = (_2952 * 2.0) - float3(1.0);\n        float2 _2960 = _2955.xy * _460.fa_maps.x;\n        float3 _3935 = _2955;\n        _3935.x = _2960.x;\n        _3935.y = _2960.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3935;\n        _3794 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _460.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2989 = fa_tex_fix(param_12, param_13);\n    float4 _3938 = mrt;\n    _3938.x = _2989.x;\n    _3938.y = _2989.y;\n    _3938.z = _2989.z;\n    mrt = _3938;\n    float4 _3017 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _460.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3017.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3029 = fa_tex_fix(param_16, param_17);\n    float param_18 = _460.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3059 = fa_tex_fix(param_20, param_21);\n    float _3799 = _460.fa_layers_a.x;\n    float _3800 = _460.fa_layers_a.y;\n    float _3803 = _460.fa_layers_a.z;\n    float _3802 = _460.fa_layers_b.w;\n    float _3805 = _460.fa_layers_c.x;\n    if (_460.fa_layers_c.z > 0.5)\n    {\n        if (mod(_460.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3799 *= _3029.y;\n            _3800 *= _3029.z;\n            _3802 *= _3017.w;\n        }\n        if (_460.fa_layers_c.z > 1.5)\n        {\n            _3803 *= mrt.x;\n            _3805 *= mrt.w;\n        }\n    }\n    return Surface{ _2920.xyz, _2920.w, _3794, fast::clamp(_460.fa_pbr.x * _2989.z, 0.0, 1.0), fast::clamp(_460.fa_pbr.y * _2989.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_460.fa_maps.y * (_3029.x - 1.0)), _460.fa_emissive.xyz + (_460.fa_model_emissive.xyz * _3059), _3799, _3800, _460.fa_layers_b.xyz, _3802, _3803, _460.fa_layers_a.w, _3805, _460.fa_layers_c.y, _460.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _698 = rect.zw - rect.xy;\n    float2 _702 = _698 * atlas;\n    float2 _706 = ddx * _702;\n    float2 _710 = ddy * _702;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _698)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_706, _706), dot(_710, _710)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _745 = _460.fa_counts.y < 0.5;\n    bool _752;\n    if (!_745)\n    {\n        _752 = _460.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _752 = _745;\n    }\n    if (_752)\n    {\n        return;\n    }\n    float3 _758 = dfdx(world_pos);\n    float3 _761 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _765 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _460);\n    int _769 = int(_765.w);\n    if (_769 < 1)\n    {\n        return;\n    }\n    int _779 = int(_460.fa_counts.y + 0.5);\n    int param_1 = _779;\n    float4 _783 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _786 = _783.yz;\n    int _790 = int(_783.w);\n    int param_2 = _779 + 1;\n    float4 _795 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _796 = _795.x;\n    int _802 = int(_460.fa_counts.w + 0.5) - 1;\n    int _806 = int(_765.z);\n    float3 _1072;\n    for (int k = 0; k < _769; k++)\n    {\n        int _819 = _806 + k;\n        int param_3 = _790 + (_819 >> 2);\n        int _837 = (_779 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_819 & 3]) * 7);\n        int param_4 = _837 + 6;\n        float4 _842 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_842.w + 0.5) >> _802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _837;\n        float4 _857 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _837 + 1;\n        float4 _862 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _837 + 2;\n        float4 _867 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _870 = _857.xyz;\n        float _875 = dot(_870, world_pos) + _857.w;\n        float3 _877 = _862.xyz;\n        float _882 = dot(_877, world_pos) + _862.w;\n        float3 _884 = _867.xyz;\n        float _889 = dot(_884, world_pos) + _867.w;\n        bool _894 = abs(_875) > 0.5;\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_882) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        bool _910;\n        if (!_902)\n        {\n            _910 = abs(_889) > 0.5;\n        }\n        else\n        {\n            _910 = _902;\n        }\n        if (_910)\n        {\n            continue;\n        }\n        float _925 = fast::clamp(dot(geo_normal, fast::normalize(_884)) * _842.z, 0.0, 1.0);\n        if (_925 <= 0.0)\n        {\n            continue;\n        }\n        float _945 = (fast::clamp((0.5 - abs(_889)) * 10.0, 0.0, 1.0) * _925) * _842.x;\n        float2 _953 = float2(_875 + 0.5, 0.5 - _882);\n        float2 _963 = float2(dot(_870, _758), dot(_877, _758));\n        float2 _973 = float2(dot(_870, _761), dot(_877, _761));\n        int param_8 = _837 + 5;\n        float4 _978 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _837 + 3;\n        float4 _983 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _837 + 4;\n        float4 _988 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _978.xyz;\n        bool _998 = _983.z > _983.x;\n        if (_998)\n        {\n            float4 param_11 = _983;\n            float2 param_12 = _953;\n            float2 param_13 = _786;\n            float2 param_14 = _963;\n            float2 param_15 = _973;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_796 > 0.5) && (_796 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1024 = fa_dc_to_linear(param_16);\n                float4 _3850 = tx;\n                _3850.x = _1024.x;\n                _3850.y = _1024.y;\n                _3850.z = _1024.z;\n                tx = _3850;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_945 * tex_a) * _978.w, 0.0, 1.0)));\n        if (_988.z > _988.x)\n        {\n            float4 param_17 = _988;\n            float2 param_18 = _953;\n            float2 param_19 = _786;\n            float2 param_20 = _963;\n            float2 param_21 = _973;\n            float4 _1068 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_796 > 1.5)\n            {\n                float3 param_22 = _1068.xyz;\n                float3 _1078 = fa_dc_to_srgb(param_22);\n                _1072 = _1078;\n            }\n            else\n            {\n                _1072 = _1068.xyz;\n            }\n            float3 _1088 = (_1072 * 2.0) - float3(1.0);\n            float2 _1093 = _1088.xy * _842.y;\n            float3 _1115 = (fast::normalize(_870) * _1093.x) + (fast::normalize(_877) * _1093.y);\n            float3 _1118 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1118, fast::normalize((_1118 * fast::max(_1088.z, 0.0500000007450580596923828125)) + (_1115 - (_1118 * dot(_1118, _1115)))), float3(fast::clamp(_945 * (_998 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_460.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2335 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2335;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_460.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _460, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _460.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _460, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    int param = (int(_460.fa_cl_info.x) + int(_460.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _460);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _335 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _341 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _344 = _341.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _350 = _344 < 0.5;\n    float3 l;\n    if (_350)\n    {\n        l = fast::normalize(_335.xyz);\n    }\n    else\n    {\n        float3 _362 = _335.xyz - world_pos;\n        float _364 = length(_362);\n        dist = _364;\n        l = _362 / float3(fast::max(_364, 9.9999997473787516355514526367188e-05));\n        float _379 = _364 / fast::max(_335.w, 0.001000000047497451305389404296875);\n        float _385 = fast::clamp(1.0 - (_379 * _379), 0.0, 1.0);\n        atten = _385 * _385;\n        if (_344 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _399 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _409 = _399.w;\n            int param_3 = (li * 4) + 3;\n            float4 _415 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _416 = _415.x;\n            float cos_inner = _416;\n            if (_416 > 1.5)\n            {\n                cos_inner = mix(_409, 1.0, 0.25);\n            }\n            atten *= smoothstep(_409, cos_inner, dot(-l, fast::normalize(_399.xyz)));\n        }\n    }\n    int _446;\n    if (_350)\n    {\n        _446 = 0;\n    }\n    else\n    {\n        _446 = (_344 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _341.xyz * atten, atten, 1.0, dist, _446 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1200)\n{\n    float _1190;\n    if (i == 0)\n    {\n        _1190 = _1200.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1206;\n        if (i == 1)\n        {\n            _1206 = _1200.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1214;\n            if (i == 2)\n            {\n                _1214 = _1200.fa_shadow_split.z;\n            }\n            else\n            {\n                _1214 = _1200.fa_shadow_split.w;\n            }\n            _1206 = _1214;\n        }\n        _1190 = _1206;\n    }\n    return _1190;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1247 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1251;\n    if (conv.x < 0.5)\n    {\n        _1251 = _1247;\n    }\n    else\n    {\n        _1251 = (conv.y * conv.z) / (conv.z - (_1247 * (conv.z - conv.y)));\n    }\n    return _1251;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1178 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1178), sin(_1178)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1297 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1311 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1297;\n            float2 _1330 = fa_shadow_vogel(param_3, param_4, param_5) * _1311;\n            float2 param_6 = uv + (_1330 * _1200.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1342 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1342 < (zr - (length(_1330) * plane)))\n            {\n                sum += _1342;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1386 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1386; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1386;\n        float param_11 = _1297;\n        float2 _1405 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1405 * _1200.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1405) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1386);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    float _1447 = fast::max(_1200.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1452 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1458 = sqrt(1.0 - (_1452 * _1452));\n    float _1465 = fast::min(_1458 / fast::max(_1452, 0.20000000298023223876953125), 4.0);\n    float _1470;\n    if (_1200.fa_shadow_bias.y > 0.0)\n    {\n        _1470 = _1200.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1470 = 1.5 * _1200.fa_shadow_info[ci].x;\n    }\n    float4 _1495 = _1200.fa_shadow_mat[ci] * float4(world + (n * (_1470 * _1458)), 1.0);\n    float _1502 = _1495.x;\n    bool _1505 = _1502 < _1200.fa_shadow_rect[ci].x;\n    bool _1514;\n    if (!_1505)\n    {\n        _1514 = _1502 > _1200.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1514 = _1505;\n    }\n    bool _1523;\n    if (!_1514)\n    {\n        _1523 = _1495.y < _1200.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1523 = _1514;\n    }\n    bool _1532;\n    if (!_1523)\n    {\n        _1532 = _1495.y > _1200.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1532 = _1523;\n    }\n    bool _1539;\n    if (!_1532)\n    {\n        _1539 = _1495.z > 1.0;\n    }\n    else\n    {\n        _1539 = _1532;\n    }\n    if (_1539)\n    {\n        return -1.0;\n    }\n    float _1548;\n    if (_1200.fa_shadow_bias.x > 0.0)\n    {\n        _1548 = _1200.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1548 = 1.5 * _1200.fa_shadow_info[ci].x;\n    }\n    float2 param = _1495.xy;\n    float4 param_1 = _1200.fa_shadow_rect[ci];\n    float param_2 = _1495.z - ((_1548 * (1.0 + (0.5 * _1465))) / _1447);\n    float param_3 = _1200.fa_shadow_info[ci].x;\n    float param_4 = _1447;\n    float param_5 = _1447 * 0.25;\n    float param_6 = ((_1200.fa_shadow_info[ci].x * fast::min(_1465, 3.0)) * 0.5) / _1447;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1200.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1200.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    if (_460.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1975 = int(_1200.fa_shadow_cfg.x + 0.5);\n    if (_1975 < 1)\n    {\n        return 1.0;\n    }\n    float _1990 = dot(world - _1200.fa_shadow_eye.xyz, _1200.fa_shadow_fwd.xyz);\n    int param = _1975 - 1;\n    if (_1990 > fa_shadow_split_at(param, _1200))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2002 = _1975 > 1;\n    bool _2009;\n    if (_2002)\n    {\n        _2009 = _1990 > _1200.fa_shadow_split.x;\n    }\n    else\n    {\n        _2009 = _2002;\n    }\n    if (_2009)\n    {\n        ci = 1;\n    }\n    bool _2013 = _1975 > 2;\n    bool _2020;\n    if (_2013)\n    {\n        _2020 = _1990 > _1200.fa_shadow_split.y;\n    }\n    else\n    {\n        _2020 = _2013;\n    }\n    if (_2020)\n    {\n        ci = 2;\n    }\n    bool _2024 = _1975 > 3;\n    bool _2031;\n    if (_2024)\n    {\n        _2031 = _1990 > _1200.fa_shadow_split.z;\n    }\n    else\n    {\n        _2031 = _2024;\n    }\n    if (_2031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2057 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n        s = _2057;\n        if (_2057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1200.fa_shadow_cfg.y > 0.0)\n    {\n        float _2082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2082 = fa_shadow_split_at(param_5, _1200);\n        }\n        else\n        {\n            _2082 = _1200.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2101 = _1200.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1200) - _2082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2112 = fast::clamp((_1990 - (fa_shadow_split_at(param_7, _1200) - _2101)) / _2101, 0.0, 1.0);\n        if (_2112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1975)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2133 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n                s2 = _2133;\n                if (_2133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2112);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    bool _1606 = _460.fa_pbr.z < 0.5;\n    bool _1614;\n    if (!_1606)\n    {\n        _1614 = _1200.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1614 = _1606;\n    }\n    if (_1614)\n    {\n        return 1.0;\n    }\n    int param = (int(_1200.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1627 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1628 = _1627.x;\n    if (_1628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1637 = int(_1628 + 0.5);\n    int param_1 = _1637;\n    float4 _1641 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1637 + 1;\n    float4 _1646 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1649 = _1641.y;\n    if (_1649 > 0.0)\n    {\n        float _1666 = 1.0 - smoothstep(0.75 * _1649, _1649, length(world - _1200.fa_shadow_eye.xyz));\n        fade = _1666;\n        if (_1666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1641.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1685 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1688 = abs(_1685);\n        float _1690 = _1688.x;\n        float _1692 = _1688.y;\n        bool _1693 = _1690 >= _1692;\n        bool _1701;\n        if (_1693)\n        {\n            _1701 = _1690 >= _1688.z;\n        }\n        else\n        {\n            _1701 = _1693;\n        }\n        int _1702;\n        if (_1701)\n        {\n            _1702 = (_1685.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1715;\n            if (_1692 >= _1688.z)\n            {\n                _1715 = (_1685.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1715 = (_1685.z > 0.0) ? 4 : 5;\n            }\n            _1702 = _1715;\n        }\n        face = _1702;\n    }\n    int _1734 = (_1637 + 2) + (face * 6);\n    int param_4 = _1734;\n    int param_5 = _1734 + 1;\n    int param_6 = _1734 + 3;\n    float4 _1748 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1734 + 4;\n    float4 _1753 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1734 + 5;\n    float4 _1758 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1770 = _1758.x * fast::max(dot(_1748, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1775 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1798 = fast::clamp(dot(n, _1748.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1821 = fast::min(sqrt(1.0 - (_1798 * _1798)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1748, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1824 = _1646.y;\n    float _1826;\n    if (_1824 > 0.0)\n    {\n        _1826 = _1824;\n    }\n    else\n    {\n        _1826 = 1.5 * _1770;\n    }\n    float4 _1846 = float4(world + (n * (_1826 * sqrt(1.0 - (_1775 * _1775)))), 1.0);\n    float _1850 = dot(_1748, _1846);\n    float _1853 = _1758.y;\n    if (_1850 < _1853)\n    {\n        return 1.0;\n    }\n    float2 _1868 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1846), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1846)) / float2(_1850);\n    float _1870 = _1868.x;\n    bool _1873 = _1870 < _1753.x;\n    bool _1882;\n    if (!_1873)\n    {\n        _1882 = _1870 > _1753.z;\n    }\n    else\n    {\n        _1882 = _1873;\n    }\n    bool _1891;\n    if (!_1882)\n    {\n        _1891 = _1868.y < _1753.y;\n    }\n    else\n    {\n        _1891 = _1882;\n    }\n    bool _1900;\n    if (!_1891)\n    {\n        _1900 = _1868.y > _1753.w;\n    }\n    else\n    {\n        _1900 = _1891;\n    }\n    if (_1900)\n    {\n        return 1.0;\n    }\n    float _1906 = _1646.x;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1770;\n    }\n    float2 param_10 = _1868;\n    float4 param_11 = _1753;\n    float param_12 = _1850 - (_1908 * (1.0 + (0.5 * _1821)));\n    float param_13 = _1770;\n    float param_14 = 1.0;\n    float param_15 = _1758.z * 0.25;\n    float param_16 = (_1770 * fast::min(_1821, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1853, _1758.z);\n    int param_18 = int(_1641.z + 0.5);\n    float param_19 = _1641.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_screen_tex)\n{\n    bool _2415 = _460.fa_ct_a.x < 0.5;\n    bool _2422;\n    if (!_2415)\n    {\n        _2422 = _1200.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2422 = _2415;\n    }\n    if (_2422)\n    {\n        return 1.0;\n    }\n    int param = (int(_1200.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2435 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2436 = _2435.y;\n    float len = _2436;\n    if (_2436 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2448 = length(world - _460.fa_camera_pos.xyz);\n    float _2458 = 1.0 - smoothstep(0.5 * _460.fa_ct_b.x, _460.fa_ct_b.x, _2448);\n    if (_2458 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2464 = len;\n    float _2467 = fast::min(_2464, 0.89999997615814208984375 * dist);\n    len = _2467;\n    float _2473 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2448);\n    float _2478 = _2473 + (0.5 * _2467);\n    float3 _2484 = world + (gn * _2473);\n    float _2486 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _2551;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2502 = (float(k) + _2486) * 0.083333335816860198974609375;\n        float3 _2510 = _2484 + (l * (_2502 * len));\n        float4 _2516 = float4(_2510, 1.0);\n        float _2522 = dot(_460.fa_ct_vpw, _2516);\n        if (_2522 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _2542 = float2(dot(_460.fa_ct_vpx, _2516), dot(_460.fa_ct_vpy, _2516)) / float2(_2522);\n        float _2546 = _2542.x * 0.5;\n        float _2547 = _2546 + 0.5;\n        if (_460.fa_ct_a.y > 0.5)\n        {\n            _2551 = (_2542.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2551 = 0.5 - (_2542.y * 0.5);\n        }\n        bool _2567 = _2547 < 0.0;\n        bool _2574;\n        if (!_2567)\n        {\n            _2574 = _2547 >= 1.0;\n        }\n        else\n        {\n            _2574 = _2567;\n        }\n        bool _2581;\n        if (!_2574)\n        {\n            _2581 = _2551 < 0.0;\n        }\n        else\n        {\n            _2581 = _2574;\n        }\n        bool _2588;\n        if (!_2581)\n        {\n            _2588 = _2551 >= 1.0;\n        }\n        else\n        {\n            _2588 = _2581;\n        }\n        if (_2588)\n        {\n            break;\n        }\n        float4 _2607 = fa_screen_tex.read(uint2(int2(float2(_2547, _2551) * _460.fa_ct_a.zw)), 0);\n        if (_2607.w < 0.5)\n        {\n            continue;\n        }\n        float _2626 = (dot(_460.fa_ct_fwd.xyz, _2510) + _460.fa_ct_fwd.w) - _2607.x;\n        if ((_2626 > _2473) && (_2626 < _2478))\n        {\n            occ = fast::max(occ, (1.0 - (_2502 * _2502)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_2547, 0.5 - _2546), fast::min(_2551, 1.0 - _2551))));\n        }\n    }\n    return 1.0 - (occ * _2458);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _2702 = fa_lm.z > 0.5;\n    bool _2708;\n    if (_2702)\n    {\n        int param = li;\n        _2708 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2708 = _2702;\n    }\n    if (_2708)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2731 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3779 = _2731.direction;\n    float3 _3774 = _2731.color;\n    float _3781 = _2731.attenuation;\n    float _3776 = _2731.shadow;\n    float _3783 = _2731._distance;\n    int _3784 = _2731.type;\n    bool _2734 = _3784 == 0;\n    if (_2734 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3779;\n        float _2745 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex, fa_world_pos);\n        _3776 = _2745;\n        _3774 *= _2745;\n    }\n    else\n    {\n        bool _2756 = _3784 != 0;\n        bool _2762;\n        if (_2756)\n        {\n            _2762 = _3781 > 0.0;\n        }\n        else\n        {\n            _2762 = _2756;\n        }\n        if (_2762)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3779;\n            float _2774 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex);\n            _3776 = _2774;\n            _3774 *= _2774;\n        }\n    }\n    bool _2784 = _460.fa_ct_a.x > 0.5;\n    bool _2790;\n    if (_2784)\n    {\n        _2790 = _3781 > 0.0;\n    }\n    else\n    {\n        _2790 = _2784;\n    }\n    if (_2790)\n    {\n        float _2797;\n        if (_2734)\n        {\n            _2797 = 1000000000.0;\n        }\n        else\n        {\n            _2797 = _3783;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _3779;\n        float param_14 = _2797;\n        float _2815 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_screen_tex);\n        _3776 *= _2815;\n        _3774 *= _2815;\n    }\n    return LightSample{ _3779, _3774, _3781, _3776, _3783, _3784 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1200)\n{\n    if (_1200.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2157 = int(_1200.fa_shadow_cfg.x + 0.5);\n    float _2167 = dot(world - _1200.fa_shadow_eye.xyz, _1200.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2172 = _2157 > 0;\n    bool _2181;\n    if (_2172)\n    {\n        int param = _2157 - 1;\n        _2181 = _2167 <= fa_shadow_split_at(param, _1200);\n    }\n    else\n    {\n        _2181 = _2172;\n    }\n    if (_2181)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2188 = _2157 > 1;\n        bool _2195;\n        if (_2188)\n        {\n            _2195 = _2167 > _1200.fa_shadow_split.x;\n        }\n        else\n        {\n            _2195 = _2188;\n        }\n        if (_2195)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2201 = _2157 > 2;\n        bool _2208;\n        if (_2201)\n        {\n            _2208 = _2167 > _1200.fa_shadow_split.y;\n        }\n        else\n        {\n            _2208 = _2201;\n        }\n        if (_2208)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2214 = _2157 > 3;\n        bool _2221;\n        if (_2214)\n        {\n            _2221 = _2167 > _1200.fa_shadow_split.z;\n        }\n        else\n        {\n            _2221 = _2214;\n        }\n        if (_2221)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _460 [[buffer(1)]], constant fa_shadows& _1200 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3615 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3615 = -_3615;\n    }\n    float3 _3201 = fast::normalize(_460.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _460, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n    Surface _3209 = fa_standard_surface(param_1, _460, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3646 = _3209.albedo;\n    float _3647 = _3209.alpha;\n    float3 _3648 = _3209.normal;\n    float _3649 = _3209.metallic;\n    float _3650 = _3209.roughness;\n    float _3651 = _3209.occlusion;\n    float3 _3652 = _3209.emission;\n    float _3653 = _3209.clearcoat;\n    float _3654 = _3209.clearcoat_roughness;\n    float3 _3655 = _3209.sheen_color;\n    float _3656 = _3209.sheen_roughness;\n    float _3657 = _3209.anisotropy;\n    float _3658 = _3209.anisotropy_rotation;\n    float _3659 = _3209.specular;\n    float _3660 = _3209.ior;\n    float3 _3661 = _3209.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n    Surface param_3 = _3209;\n    surface(param_2, param_3);\n    _3646 = param_3.albedo;\n    _3647 = param_3.alpha;\n    _3648 = param_3.normal;\n    _3649 = param_3.metallic;\n    _3650 = param_3.roughness;\n    _3651 = param_3.occlusion;\n    _3652 = param_3.emission;\n    _3653 = param_3.clearcoat;\n    _3654 = param_3.clearcoat_roughness;\n    _3655 = param_3.sheen_color;\n    _3656 = param_3.sheen_roughness;\n    _3657 = param_3.anisotropy;\n    _3658 = param_3.anisotropy_rotation;\n    _3659 = param_3.specular;\n    _3660 = param_3.ior;\n    _3661 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3615;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _460, fa_decal_tex, fa_env_smp);\n    _3646 = param_6;\n    _3648 = param_7;\n    float3 result;\n    if (_460.fa_emissive.w > 0.5)\n    {\n        result = _3646;\n    }\n    else\n    {\n        float3 _3247 = _3648;\n        float3 _3248 = fast::normalize(_3247);\n        _3648 = _3248;\n        float3 param_8 = _3248;\n        float3 lit = (fa_indirect_diffuse(param_8, _460, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _3646) * _3651;\n        int _3267 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3267; ln++)\n        {\n            int param_9 = ln;\n            int _3280 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _460, fa_cl_ndir, fa_cl_slot);\n            bool _3283 = in.fa_lm.z > 0.5;\n            bool _3289;\n            if (_3283)\n            {\n                int param_10 = _3280;\n                _3289 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            if (_3289)\n            {\n                continue;\n            }\n            int param_11 = _3280;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3615;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3646, _3647, _3648, _3649, _3650, _3651, _3652, _3653, _3654, _3655, _3656, _3657, _3658, _3659, _3660, _3661 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3316 = result;\n    float3 _3317 = _3316 + _3652;\n    result = _3317;\n    float3 param_17 = _3317;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1200);\n    bool _3326 = _460.fa_fog.w > 0.0;\n    bool _3333;\n    if (!_3326)\n    {\n        _3333 = _460.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3333 = _3326;\n    }\n    if (_3333)\n    {\n        float3 _3342 = in.fa_world_pos - _460.fa_camera_pos.xyz;\n        float _3348 = dot(_3342, _460.fa_fog_c.xyz);\n        bool _3352 = _460.fa_fog_c.w > 0.5;\n        float _3353;\n        if (_3352)\n        {\n            _3353 = _3348;\n        }\n        else\n        {\n            _3353 = length(_3342);\n        }\n        float _3365 = _3353 - _460.fa_fog_b.x;\n        if (_3365 > 0.0)\n        {\n            float _3374 = _460.fa_fog.w * _3365;\n            float tau = _3374 * _3374;\n            if (_460.fa_fog_b.y > 0.0)\n            {\n                float _3390;\n                if (_3352)\n                {\n                    _3390 = in.fa_world_pos.y - (_460.fa_fog_c.y * _3348);\n                }\n                else\n                {\n                    _3390 = _460.fa_camera_pos.y;\n                }\n                float _3411 = mix(_3390, in.fa_world_pos.y, fast::clamp(_460.fa_fog_b.x / _3353, 0.0, 1.0));\n                float _3415 = in.fa_world_pos.y - _3411;\n                float _3420 = _3411 - _460.fa_fog_b.z;\n                float _3425 = in.fa_world_pos.y - _460.fa_fog_b.z;\n                bool _3428 = _3420 <= 0.0;\n                bool _3429 = !_3428;\n                bool _3435;\n                if (_3429)\n                {\n                    _3435 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3435 = _3428;\n                }\n                float _3436;\n                if (_3435)\n                {\n                    _3436 = _460.fa_fog_b.y;\n                }\n                else\n                {\n                    _3436 = _460.fa_fog_b.y * exp(-fast::min(_460.fa_fog_b.w * _3420, 80.0));\n                }\n                bool _3463;\n                if (_3429)\n                {\n                    _3463 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3463 = _3428;\n                }\n                float _3464;\n                if (_3463)\n                {\n                    _3464 = _460.fa_fog_b.y * _3420;\n                }\n                else\n                {\n                    _3464 = (_460.fa_fog_b.y * (1.0 - exp(-fast::min(_460.fa_fog_b.w * _3420, 80.0)))) / _460.fa_fog_b.w;\n                }\n                bool _3489 = _3425 <= 0.0;\n                bool _3496;\n                if (!_3489)\n                {\n                    _3496 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3496 = _3489;\n                }\n                float _3497;\n                if (_3496)\n                {\n                    _3497 = _460.fa_fog_b.y * _3425;\n                }\n                else\n                {\n                    _3497 = (_460.fa_fog_b.y * (1.0 - exp(-fast::min(_460.fa_fog_b.w * _3425, 80.0)))) / _460.fa_fog_b.w;\n                }\n                float _3524;\n                if (abs(_3415) < 0.001000000047497451305389404296875)\n                {\n                    _3524 = _3436;\n                }\n                else\n                {\n                    _3524 = (_3497 - _3464) / _3415;\n                }\n                tau += (_3365 * fast::max(_3524, 0.0));\n            }\n            result = mix(result, _460.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3647);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_460",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1200",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    bool _465 = _460.fa_cl_info.x < 0.0;\n    bool _472;\n    if (!_465)\n    {\n        _472 = _460.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _480;\n    if (!_472)\n    {\n        _480 = _460.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _480 = _472;\n    }\n    bool _487;\n    if (!_480)\n    {\n        _487 = _460.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _487 = _480;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _460.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    if (_494)\n    {\n        return float4(0.0);\n    }\n    float4 _504 = float4(world_pos, 1.0);\n    float _511 = dot(_460.fa_cl_vpw, _504);\n    if (!(_511 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _533 = float2(dot(_460.fa_cl_vpx, _504), dot(_460.fa_cl_vpy, _504)) / float2(_511);\n    int _537 = int(_460.fa_cl_grid.x);\n    int _541 = int(_460.fa_cl_grid.y);\n    int param = (int(_460.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_460.fa_cl_fwd.xyz, world_pos) + _460.fa_cl_fwd.w, _460.fa_cl_grid.w) / _460.fa_cl_grid.w) * _460.fa_cl_grid.z)), 0, int(_460.fa_cl_info.y) - 1) * _541) + clamp(int(floor(((_533.y * 0.5) + 0.5) * _460.fa_cl_grid.y)), 0, _541 - 1)) * _537)) + clamp(int(floor(((_533.x * 0.5) + 0.5) * _460.fa_cl_grid.x)), 0, _537 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    float3 param = world_pos;\n    float4 _617 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _460);\n    return int2(int(_617.x), int(_617.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_460.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2675 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _460);\n    fa_cl_slot = _2675.x;\n    fa_cl_local = _2675.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2867 = fa_linear_to_srgb(param);\n        c = _2867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2875 = fa_srgb_to_linear(param_1);\n            c = _2875;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _225;\n    if (bool(i.front_facing))\n    {\n        _225 = i.world_normal;\n    }\n    else\n    {\n        _225 = -i.world_normal;\n    }\n    float3 _249 = fast::normalize(i.world_tangent.xyz - (_225 * dot(_225, i.world_tangent.xyz)));\n    float3 _276 = fast::normalize(((_249 * m.x) + ((cross(_225, _249) * i.world_tangent.w) * m.y)) + (_225 * m.z));\n    float3 _279;\n    if (bool(i.front_facing))\n    {\n        _279 = _276;\n    }\n    else\n    {\n        _279 = -_276;\n    }\n    return _279;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _460, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _460.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2906 = fa_tex_fix(param_2, param_3);\n    float4 _3927 = base_t;\n    _3927.x = _2906.x;\n    _3927.y = _2906.y;\n    _3927.z = _2906.z;\n    base_t = _3927;\n    float4 _2920 = (_3927 * _460.fa_base_color) * i.vertex_color;\n    float3 _3794 = i.world_normal;\n    if (_460.fa_maps.z > 0.5)\n    {\n        float param_4 = _460.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2952 = fa_tex_fix(param_6, param_7);\n        float3 _2955 = (_2952 * 2.0) - float3(1.0);\n        float2 _2960 = _2955.xy * _460.fa_maps.x;\n        float3 _3935 = _2955;\n        _3935.x = _2960.x;\n        _3935.y = _2960.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3935;\n        _3794 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _460.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2989 = fa_tex_fix(param_12, param_13);\n    float4 _3938 = mrt;\n    _3938.x = _2989.x;\n    _3938.y = _2989.y;\n    _3938.z = _2989.z;\n    mrt = _3938;\n    float4 _3017 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _460.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3017.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3029 = fa_tex_fix(param_16, param_17);\n    float param_18 = _460.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3059 = fa_tex_fix(param_20, param_21);\n    float _3799 = _460.fa_layers_a.x;\n    float _3800 = _460.fa_layers_a.y;\n    float _3803 = _460.fa_layers_a.z;\n    float _3802 = _460.fa_layers_b.w;\n    float _3805 = _460.fa_layers_c.x;\n    if (_460.fa_layers_c.z > 0.5)\n    {\n        if (mod(_460.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3799 *= _3029.y;\n            _3800 *= _3029.z;\n            _3802 *= _3017.w;\n        }\n        if (_460.fa_layers_c.z > 1.5)\n        {\n            _3803 *= mrt.x;\n            _3805 *= mrt.w;\n        }\n    }\n    return Surface{ _2920.xyz, _2920.w, _3794, fast::clamp(_460.fa_pbr.x * _2989.z, 0.0, 1.0), fast::clamp(_460.fa_pbr.y * _2989.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_460.fa_maps.y * (_3029.x - 1.0)), _460.fa_emissive.xyz + (_460.fa_model_emissive.xyz * _3059), _3799, _3800, _460.fa_layers_b.xyz, _3802, _3803, _460.fa_layers_a.w, _3805, _460.fa_layers_c.y, _460.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _698 = rect.zw - rect.xy;\n    float2 _702 = _698 * atlas;\n    float2 _706 = ddx * _702;\n    float2 _710 = ddy * _702;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _698)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_706, _706), dot(_710, _710)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _745 = _460.fa_counts.y < 0.5;\n    bool _752;\n    if (!_745)\n    {\n        _752 = _460.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _752 = _745;\n    }\n    if (_752)\n    {\n        return;\n    }\n    float3 _758 = dfdx(world_pos);\n    float3 _761 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _765 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _460);\n    int _769 = int(_765.w);\n    if (_769 < 1)\n    {\n        return;\n    }\n    int _779 = int(_460.fa_counts.y + 0.5);\n    int param_1 = _779;\n    float4 _783 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _786 = _783.yz;\n    int _790 = int(_783.w);\n    int param_2 = _779 + 1;\n    float4 _795 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _796 = _795.x;\n    int _802 = int(_460.fa_counts.w + 0.5) - 1;\n    int _806 = int(_765.z);\n    float3 _1072;\n    for (int k = 0; k < _769; k++)\n    {\n        int _819 = _806 + k;\n        int param_3 = _790 + (_819 >> 2);\n        int _837 = (_779 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_819 & 3]) * 7);\n        int param_4 = _837 + 6;\n        float4 _842 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_842.w + 0.5) >> _802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _837;\n        float4 _857 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _837 + 1;\n        float4 _862 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _837 + 2;\n        float4 _867 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _870 = _857.xyz;\n        float _875 = dot(_870, world_pos) + _857.w;\n        float3 _877 = _862.xyz;\n        float _882 = dot(_877, world_pos) + _862.w;\n        float3 _884 = _867.xyz;\n        float _889 = dot(_884, world_pos) + _867.w;\n        bool _894 = abs(_875) > 0.5;\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_882) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        bool _910;\n        if (!_902)\n        {\n            _910 = abs(_889) > 0.5;\n        }\n        else\n        {\n            _910 = _902;\n        }\n        if (_910)\n        {\n            continue;\n        }\n        float _925 = fast::clamp(dot(geo_normal, fast::normalize(_884)) * _842.z, 0.0, 1.0);\n        if (_925 <= 0.0)\n        {\n            continue;\n        }\n        float _945 = (fast::clamp((0.5 - abs(_889)) * 10.0, 0.0, 1.0) * _925) * _842.x;\n        float2 _953 = float2(_875 + 0.5, 0.5 - _882);\n        float2 _963 = float2(dot(_870, _758), dot(_877, _758));\n        float2 _973 = float2(dot(_870, _761), dot(_877, _761));\n        int param_8 = _837 + 5;\n        float4 _978 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _837 + 3;\n        float4 _983 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _837 + 4;\n        float4 _988 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _978.xyz;\n        bool _998 = _983.z > _983.x;\n        if (_998)\n        {\n            float4 param_11 = _983;\n            float2 param_12 = _953;\n            float2 param_13 = _786;\n            float2 param_14 = _963;\n            float2 param_15 = _973;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_796 > 0.5) && (_796 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1024 = fa_dc_to_linear(param_16);\n                float4 _3850 = tx;\n                _3850.x = _1024.x;\n                _3850.y = _1024.y;\n                _3850.z = _1024.z;\n                tx = _3850;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_945 * tex_a) * _978.w, 0.0, 1.0)));\n        if (_988.z > _988.x)\n        {\n            float4 param_17 = _988;\n            float2 param_18 = _953;\n            float2 param_19 = _786;\n            float2 param_20 = _963;\n            float2 param_21 = _973;\n            float4 _1068 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_796 > 1.5)\n            {\n                float3 param_22 = _1068.xyz;\n                float3 _1078 = fa_dc_to_srgb(param_22);\n                _1072 = _1078;\n            }\n            else\n            {\n                _1072 = _1068.xyz;\n            }\n            float3 _1088 = (_1072 * 2.0) - float3(1.0);\n            float2 _1093 = _1088.xy * _842.y;\n            float3 _1115 = (fast::normalize(_870) * _1093.x) + (fast::normalize(_877) * _1093.y);\n            float3 _1118 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1118, fast::normalize((_1118 * fast::max(_1088.z, 0.0500000007450580596923828125)) + (_1115 - (_1118 * dot(_1118, _1115)))), float3(fast::clamp(_945 * (_998 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_460.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2335 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2335;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_460.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _460, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _460.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _460, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _460, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460)\n{\n    int param = (int(_460.fa_cl_info.x) + int(_460.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _460);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _335 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _341 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _344 = _341.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _350 = _344 < 0.5;\n    float3 l;\n    if (_350)\n    {\n        l = fast::normalize(_335.xyz);\n    }\n    else\n    {\n        float3 _362 = _335.xyz - world_pos;\n        float _364 = length(_362);\n        dist = _364;\n        l = _362 / float3(fast::max(_364, 9.9999997473787516355514526367188e-05));\n        float _379 = _364 / fast::max(_335.w, 0.001000000047497451305389404296875);\n        float _385 = fast::clamp(1.0 - (_379 * _379), 0.0, 1.0);\n        atten = _385 * _385;\n        if (_344 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _399 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _409 = _399.w;\n            int param_3 = (li * 4) + 3;\n            float4 _415 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _416 = _415.x;\n            float cos_inner = _416;\n            if (_416 > 1.5)\n            {\n                cos_inner = mix(_409, 1.0, 0.25);\n            }\n            atten *= smoothstep(_409, cos_inner, dot(-l, fast::normalize(_399.xyz)));\n        }\n    }\n    int _446;\n    if (_350)\n    {\n        _446 = 0;\n    }\n    else\n    {\n        _446 = (_344 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _341.xyz * atten, atten, 1.0, dist, _446 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1200)\n{\n    float _1190;\n    if (i == 0)\n    {\n        _1190 = _1200.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1206;\n        if (i == 1)\n        {\n            _1206 = _1200.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1214;\n            if (i == 2)\n            {\n                _1214 = _1200.fa_shadow_split.z;\n            }\n            else\n            {\n                _1214 = _1200.fa_shadow_split.w;\n            }\n            _1206 = _1214;\n        }\n        _1190 = _1206;\n    }\n    return _1190;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1247 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1251;\n    if (conv.x < 0.5)\n    {\n        _1251 = _1247;\n    }\n    else\n    {\n        _1251 = (conv.y * conv.z) / (conv.z - (_1247 * (conv.z - conv.y)));\n    }\n    return _1251;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1178 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1178), sin(_1178)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1297 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1311 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1297;\n            float2 _1330 = fa_shadow_vogel(param_3, param_4, param_5) * _1311;\n            float2 param_6 = uv + (_1330 * _1200.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1342 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1342 < (zr - (length(_1330) * plane)))\n            {\n                sum += _1342;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1386 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1386; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1386;\n        float param_11 = _1297;\n        float2 _1405 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1405 * _1200.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1405) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1386);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    float _1447 = fast::max(_1200.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1452 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1458 = sqrt(1.0 - (_1452 * _1452));\n    float _1465 = fast::min(_1458 / fast::max(_1452, 0.20000000298023223876953125), 4.0);\n    float _1470;\n    if (_1200.fa_shadow_bias.y > 0.0)\n    {\n        _1470 = _1200.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1470 = 1.5 * _1200.fa_shadow_info[ci].x;\n    }\n    float4 _1495 = _1200.fa_shadow_mat[ci] * float4(world + (n * (_1470 * _1458)), 1.0);\n    float _1502 = _1495.x;\n    bool _1505 = _1502 < _1200.fa_shadow_rect[ci].x;\n    bool _1514;\n    if (!_1505)\n    {\n        _1514 = _1502 > _1200.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1514 = _1505;\n    }\n    bool _1523;\n    if (!_1514)\n    {\n        _1523 = _1495.y < _1200.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1523 = _1514;\n    }\n    bool _1532;\n    if (!_1523)\n    {\n        _1532 = _1495.y > _1200.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1532 = _1523;\n    }\n    bool _1539;\n    if (!_1532)\n    {\n        _1539 = _1495.z > 1.0;\n    }\n    else\n    {\n        _1539 = _1532;\n    }\n    if (_1539)\n    {\n        return -1.0;\n    }\n    float _1548;\n    if (_1200.fa_shadow_bias.x > 0.0)\n    {\n        _1548 = _1200.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1548 = 1.5 * _1200.fa_shadow_info[ci].x;\n    }\n    float2 param = _1495.xy;\n    float4 param_1 = _1200.fa_shadow_rect[ci];\n    float param_2 = _1495.z - ((_1548 * (1.0 + (0.5 * _1465))) / _1447);\n    float param_3 = _1200.fa_shadow_info[ci].x;\n    float param_4 = _1447;\n    float param_5 = _1447 * 0.25;\n    float param_6 = ((_1200.fa_shadow_info[ci].x * fast::min(_1465, 3.0)) * 0.5) / _1447;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1200.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1200.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    if (_460.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1975 = int(_1200.fa_shadow_cfg.x + 0.5);\n    if (_1975 < 1)\n    {\n        return 1.0;\n    }\n    float _1990 = dot(world - _1200.fa_shadow_eye.xyz, _1200.fa_shadow_fwd.xyz);\n    int param = _1975 - 1;\n    if (_1990 > fa_shadow_split_at(param, _1200))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2002 = _1975 > 1;\n    bool _2009;\n    if (_2002)\n    {\n        _2009 = _1990 > _1200.fa_shadow_split.x;\n    }\n    else\n    {\n        _2009 = _2002;\n    }\n    if (_2009)\n    {\n        ci = 1;\n    }\n    bool _2013 = _1975 > 2;\n    bool _2020;\n    if (_2013)\n    {\n        _2020 = _1990 > _1200.fa_shadow_split.y;\n    }\n    else\n    {\n        _2020 = _2013;\n    }\n    if (_2020)\n    {\n        ci = 2;\n    }\n    bool _2024 = _1975 > 3;\n    bool _2031;\n    if (_2024)\n    {\n        _2031 = _1990 > _1200.fa_shadow_split.z;\n    }\n    else\n    {\n        _2031 = _2024;\n    }\n    if (_2031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2057 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n        s = _2057;\n        if (_2057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1200.fa_shadow_cfg.y > 0.0)\n    {\n        float _2082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2082 = fa_shadow_split_at(param_5, _1200);\n        }\n        else\n        {\n            _2082 = _1200.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2101 = _1200.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1200) - _2082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2112 = fast::clamp((_1990 - (fa_shadow_split_at(param_7, _1200) - _2101)) / _2101, 0.0, 1.0);\n        if (_2112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1975)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2133 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex);\n                s2 = _2133;\n                if (_2133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2112);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex)\n{\n    bool _1606 = _460.fa_pbr.z < 0.5;\n    bool _1614;\n    if (!_1606)\n    {\n        _1614 = _1200.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1614 = _1606;\n    }\n    if (_1614)\n    {\n        return 1.0;\n    }\n    int param = (int(_1200.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1627 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1628 = _1627.x;\n    if (_1628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1637 = int(_1628 + 0.5);\n    int param_1 = _1637;\n    float4 _1641 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1637 + 1;\n    float4 _1646 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1649 = _1641.y;\n    if (_1649 > 0.0)\n    {\n        float _1666 = 1.0 - smoothstep(0.75 * _1649, _1649, length(world - _1200.fa_shadow_eye.xyz));\n        fade = _1666;\n        if (_1666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1641.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1685 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1688 = abs(_1685);\n        float _1690 = _1688.x;\n        float _1692 = _1688.y;\n        bool _1693 = _1690 >= _1692;\n        bool _1701;\n        if (_1693)\n        {\n            _1701 = _1690 >= _1688.z;\n        }\n        else\n        {\n            _1701 = _1693;\n        }\n        int _1702;\n        if (_1701)\n        {\n            _1702 = (_1685.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1715;\n            if (_1692 >= _1688.z)\n            {\n                _1715 = (_1685.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1715 = (_1685.z > 0.0) ? 4 : 5;\n            }\n            _1702 = _1715;\n        }\n        face = _1702;\n    }\n    int _1734 = (_1637 + 2) + (face * 6);\n    int param_4 = _1734;\n    int param_5 = _1734 + 1;\n    int param_6 = _1734 + 3;\n    float4 _1748 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1734 + 4;\n    float4 _1753 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1734 + 5;\n    float4 _1758 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1770 = _1758.x * fast::max(dot(_1748, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1775 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1798 = fast::clamp(dot(n, _1748.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1821 = fast::min(sqrt(1.0 - (_1798 * _1798)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1748, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1824 = _1646.y;\n    float _1826;\n    if (_1824 > 0.0)\n    {\n        _1826 = _1824;\n    }\n    else\n    {\n        _1826 = 1.5 * _1770;\n    }\n    float4 _1846 = float4(world + (n * (_1826 * sqrt(1.0 - (_1775 * _1775)))), 1.0);\n    float _1850 = dot(_1748, _1846);\n    float _1853 = _1758.y;\n    if (_1850 < _1853)\n    {\n        return 1.0;\n    }\n    float2 _1868 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1846), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1846)) / float2(_1850);\n    float _1870 = _1868.x;\n    bool _1873 = _1870 < _1753.x;\n    bool _1882;\n    if (!_1873)\n    {\n        _1882 = _1870 > _1753.z;\n    }\n    else\n    {\n        _1882 = _1873;\n    }\n    bool _1891;\n    if (!_1882)\n    {\n        _1891 = _1868.y < _1753.y;\n    }\n    else\n    {\n        _1891 = _1882;\n    }\n    bool _1900;\n    if (!_1891)\n    {\n        _1900 = _1868.y > _1753.w;\n    }\n    else\n    {\n        _1900 = _1891;\n    }\n    if (_1900)\n    {\n        return 1.0;\n    }\n    float _1906 = _1646.x;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1770;\n    }\n    float2 param_10 = _1868;\n    float4 param_11 = _1753;\n    float param_12 = _1850 - (_1908 * (1.0 + (0.5 * _1821)));\n    float param_13 = _1770;\n    float param_14 = 1.0;\n    float param_15 = _1758.z * 0.25;\n    float param_16 = (_1770 * fast::min(_1821, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1853, _1758.z);\n    int param_18 = int(_1641.z + 0.5);\n    float param_19 = _1641.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1200, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_screen_tex)\n{\n    bool _2415 = _460.fa_ct_a.x < 0.5;\n    bool _2422;\n    if (!_2415)\n    {\n        _2422 = _1200.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2422 = _2415;\n    }\n    if (_2422)\n    {\n        return 1.0;\n    }\n    int param = (int(_1200.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2435 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2436 = _2435.y;\n    float len = _2436;\n    if (_2436 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2448 = length(world - _460.fa_camera_pos.xyz);\n    float _2458 = 1.0 - smoothstep(0.5 * _460.fa_ct_b.x, _460.fa_ct_b.x, _2448);\n    if (_2458 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2464 = len;\n    float _2467 = fast::min(_2464, 0.89999997615814208984375 * dist);\n    len = _2467;\n    float _2473 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2448);\n    float _2478 = _2473 + (0.5 * _2467);\n    float3 _2484 = world + (gn * _2473);\n    float _2486 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _2551;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2502 = (float(k) + _2486) * 0.083333335816860198974609375;\n        float3 _2510 = _2484 + (l * (_2502 * len));\n        float4 _2516 = float4(_2510, 1.0);\n        float _2522 = dot(_460.fa_ct_vpw, _2516);\n        if (_2522 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _2542 = float2(dot(_460.fa_ct_vpx, _2516), dot(_460.fa_ct_vpy, _2516)) / float2(_2522);\n        float _2546 = _2542.x * 0.5;\n        float _2547 = _2546 + 0.5;\n        if (_460.fa_ct_a.y > 0.5)\n        {\n            _2551 = (_2542.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2551 = 0.5 - (_2542.y * 0.5);\n        }\n        bool _2567 = _2547 < 0.0;\n        bool _2574;\n        if (!_2567)\n        {\n            _2574 = _2547 >= 1.0;\n        }\n        else\n        {\n            _2574 = _2567;\n        }\n        bool _2581;\n        if (!_2574)\n        {\n            _2581 = _2551 < 0.0;\n        }\n        else\n        {\n            _2581 = _2574;\n        }\n        bool _2588;\n        if (!_2581)\n        {\n            _2588 = _2551 >= 1.0;\n        }\n        else\n        {\n            _2588 = _2581;\n        }\n        if (_2588)\n        {\n            break;\n        }\n        float4 _2607 = fa_screen_tex.read(uint2(int2(float2(_2547, _2551) * _460.fa_ct_a.zw)), 0);\n        if (_2607.w < 0.5)\n        {\n            continue;\n        }\n        float _2626 = (dot(_460.fa_ct_fwd.xyz, _2510) + _460.fa_ct_fwd.w) - _2607.x;\n        if ((_2626 > _2473) && (_2626 < _2478))\n        {\n            occ = fast::max(occ, (1.0 - (_2502 * _2502)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_2547, 0.5 - _2546), fast::min(_2551, 1.0 - _2551))));\n        }\n    }\n    return 1.0 - (occ * _2458);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _460, thread float4& gl_FragCoord, constant fa_shadows& _1200, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _2702 = fa_lm.z > 0.5;\n    bool _2708;\n    if (_2702)\n    {\n        int param = li;\n        _2708 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2708 = _2702;\n    }\n    if (_2708)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2731 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3779 = _2731.direction;\n    float3 _3774 = _2731.color;\n    float _3781 = _2731.attenuation;\n    float _3776 = _2731.shadow;\n    float _3783 = _2731._distance;\n    int _3784 = _2731.type;\n    bool _2734 = _3784 == 0;\n    if (_2734 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3779;\n        float _2745 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex, fa_world_pos);\n        _3776 = _2745;\n        _3774 *= _2745;\n    }\n    else\n    {\n        bool _2756 = _3784 != 0;\n        bool _2762;\n        if (_2756)\n        {\n            _2762 = _3781 > 0.0;\n        }\n        else\n        {\n            _2762 = _2756;\n        }\n        if (_2762)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3779;\n            float _2774 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex);\n            _3776 = _2774;\n            _3774 *= _2774;\n        }\n    }\n    bool _2784 = _460.fa_ct_a.x > 0.5;\n    bool _2790;\n    if (_2784)\n    {\n        _2790 = _3781 > 0.0;\n    }\n    else\n    {\n        _2790 = _2784;\n    }\n    if (_2790)\n    {\n        float _2797;\n        if (_2734)\n        {\n            _2797 = 1000000000.0;\n        }\n        else\n        {\n            _2797 = _3783;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _3779;\n        float param_14 = _2797;\n        float _2815 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_screen_tex);\n        _3776 *= _2815;\n        _3774 *= _2815;\n    }\n    return LightSample{ _3779, _3774, _3781, _3776, _3783, _3784 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1200)\n{\n    if (_1200.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2157 = int(_1200.fa_shadow_cfg.x + 0.5);\n    float _2167 = dot(world - _1200.fa_shadow_eye.xyz, _1200.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2172 = _2157 > 0;\n    bool _2181;\n    if (_2172)\n    {\n        int param = _2157 - 1;\n        _2181 = _2167 <= fa_shadow_split_at(param, _1200);\n    }\n    else\n    {\n        _2181 = _2172;\n    }\n    if (_2181)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2188 = _2157 > 1;\n        bool _2195;\n        if (_2188)\n        {\n            _2195 = _2167 > _1200.fa_shadow_split.x;\n        }\n        else\n        {\n            _2195 = _2188;\n        }\n        if (_2195)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2201 = _2157 > 2;\n        bool _2208;\n        if (_2201)\n        {\n            _2208 = _2167 > _1200.fa_shadow_split.y;\n        }\n        else\n        {\n            _2208 = _2201;\n        }\n        if (_2208)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2214 = _2157 > 3;\n        bool _2221;\n        if (_2214)\n        {\n            _2221 = _2167 > _1200.fa_shadow_split.z;\n        }\n        else\n        {\n            _2221 = _2214;\n        }\n        if (_2221)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _460 [[buffer(1)]], constant fa_shadows& _1200 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3615 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3615 = -_3615;\n    }\n    float3 _3201 = fast::normalize(_460.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _460, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n    Surface _3209 = fa_standard_surface(param_1, _460, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3646 = _3209.albedo;\n    float _3647 = _3209.alpha;\n    float3 _3648 = _3209.normal;\n    float _3649 = _3209.metallic;\n    float _3650 = _3209.roughness;\n    float _3651 = _3209.occlusion;\n    float3 _3652 = _3209.emission;\n    float _3653 = _3209.clearcoat;\n    float _3654 = _3209.clearcoat_roughness;\n    float3 _3655 = _3209.sheen_color;\n    float _3656 = _3209.sheen_roughness;\n    float _3657 = _3209.anisotropy;\n    float _3658 = _3209.anisotropy_rotation;\n    float _3659 = _3209.specular;\n    float _3660 = _3209.ior;\n    float3 _3661 = _3209.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n    Surface param_3 = _3209;\n    surface(param_2, param_3);\n    _3646 = param_3.albedo;\n    _3647 = param_3.alpha;\n    _3648 = param_3.normal;\n    _3649 = param_3.metallic;\n    _3650 = param_3.roughness;\n    _3651 = param_3.occlusion;\n    _3652 = param_3.emission;\n    _3653 = param_3.clearcoat;\n    _3654 = param_3.clearcoat_roughness;\n    _3655 = param_3.sheen_color;\n    _3656 = param_3.sheen_roughness;\n    _3657 = param_3.anisotropy;\n    _3658 = param_3.anisotropy_rotation;\n    _3659 = param_3.specular;\n    _3660 = param_3.ior;\n    _3661 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3615;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _460, fa_decal_tex, fa_env_smp);\n    _3646 = param_6;\n    _3648 = param_7;\n    float3 result;\n    if (_460.fa_emissive.w > 0.5)\n    {\n        result = _3646;\n    }\n    else\n    {\n        float3 _3247 = _3648;\n        float3 _3248 = fast::normalize(_3247);\n        _3648 = _3248;\n        float3 param_8 = _3248;\n        float3 lit = (fa_indirect_diffuse(param_8, _460, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _3646) * _3651;\n        int _3267 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3267; ln++)\n        {\n            int param_9 = ln;\n            int _3280 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _460, fa_cl_ndir, fa_cl_slot);\n            bool _3283 = in.fa_lm.z > 0.5;\n            bool _3289;\n            if (_3283)\n            {\n                int param_10 = _3280;\n                _3289 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            if (_3289)\n            {\n                continue;\n            }\n            int param_11 = _3280;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3615;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3201, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3646, _3647, _3648, _3649, _3650, _3651, _3652, _3653, _3654, _3655, _3656, _3657, _3658, _3659, _3660, _3661 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _460, gl_FragCoord, _1200, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3316 = result;\n    float3 _3317 = _3316 + _3652;\n    result = _3317;\n    float3 param_17 = _3317;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1200);\n    bool _3326 = _460.fa_fog.w > 0.0;\n    bool _3333;\n    if (!_3326)\n    {\n        _3333 = _460.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3333 = _3326;\n    }\n    if (_3333)\n    {\n        float3 _3342 = in.fa_world_pos - _460.fa_camera_pos.xyz;\n        float _3348 = dot(_3342, _460.fa_fog_c.xyz);\n        bool _3352 = _460.fa_fog_c.w > 0.5;\n        float _3353;\n        if (_3352)\n        {\n            _3353 = _3348;\n        }\n        else\n        {\n            _3353 = length(_3342);\n        }\n        float _3365 = _3353 - _460.fa_fog_b.x;\n        if (_3365 > 0.0)\n        {\n            float _3374 = _460.fa_fog.w * _3365;\n            float tau = _3374 * _3374;\n            if (_460.fa_fog_b.y > 0.0)\n            {\n                float _3390;\n                if (_3352)\n                {\n                    _3390 = in.fa_world_pos.y - (_460.fa_fog_c.y * _3348);\n                }\n                else\n                {\n                    _3390 = _460.fa_camera_pos.y;\n                }\n                float _3411 = mix(_3390, in.fa_world_pos.y, fast::clamp(_460.fa_fog_b.x / _3353, 0.0, 1.0));\n                float _3415 = in.fa_world_pos.y - _3411;\n                float _3420 = _3411 - _460.fa_fog_b.z;\n                float _3425 = in.fa_world_pos.y - _460.fa_fog_b.z;\n                bool _3428 = _3420 <= 0.0;\n                bool _3429 = !_3428;\n                bool _3435;\n                if (_3429)\n                {\n                    _3435 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3435 = _3428;\n                }\n                float _3436;\n                if (_3435)\n                {\n                    _3436 = _460.fa_fog_b.y;\n                }\n                else\n                {\n                    _3436 = _460.fa_fog_b.y * exp(-fast::min(_460.fa_fog_b.w * _3420, 80.0));\n                }\n                bool _3463;\n                if (_3429)\n                {\n                    _3463 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3463 = _3428;\n                }\n                float _3464;\n                if (_3463)\n                {\n                    _3464 = _460.fa_fog_b.y * _3420;\n                }\n                else\n                {\n                    _3464 = (_460.fa_fog_b.y * (1.0 - exp(-fast::min(_460.fa_fog_b.w * _3420, 80.0)))) / _460.fa_fog_b.w;\n                }\n                bool _3489 = _3425 <= 0.0;\n                bool _3496;\n                if (!_3489)\n                {\n                    _3496 = _460.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3496 = _3489;\n                }\n                float _3497;\n                if (_3496)\n                {\n                    _3497 = _460.fa_fog_b.y * _3425;\n                }\n                else\n                {\n                    _3497 = (_460.fa_fog_b.y * (1.0 - exp(-fast::min(_460.fa_fog_b.w * _3425, 80.0)))) / _460.fa_fog_b.w;\n                }\n                float _3524;\n                if (abs(_3415) < 0.001000000047497451305389404296875)\n                {\n                    _3524 = _3436;\n                }\n                else\n                {\n                    _3524 = (_3497 - _3464) / _3415;\n                }\n                tau += (_3365 * fast::max(_3524, 0.0));\n            }\n            result = mix(result, _460.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3647);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_460",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1200",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
