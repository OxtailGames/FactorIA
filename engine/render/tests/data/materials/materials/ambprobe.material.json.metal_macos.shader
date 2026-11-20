{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    bool _463 = _458.fa_cl_info.x < 0.0;\n    bool _470;\n    if (!_463)\n    {\n        _470 = _458.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = _458.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = _458.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _458.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return float4(0.0);\n    }\n    float4 _502 = float4(world_pos, 1.0);\n    float _509 = dot(_458.fa_cl_vpw, _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _531 = float2(dot(_458.fa_cl_vpx, _502), dot(_458.fa_cl_vpy, _502)) / float2(_509);\n    int _535 = int(_458.fa_cl_grid.x);\n    int _539 = int(_458.fa_cl_grid.y);\n    int param = (int(_458.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_458.fa_cl_fwd.xyz, world_pos) + _458.fa_cl_fwd.w, _458.fa_cl_grid.w) / _458.fa_cl_grid.w) * _458.fa_cl_grid.z)), 0, int(_458.fa_cl_info.y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5) + 0.5) * _458.fa_cl_grid.y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5) + 0.5) * _458.fa_cl_grid.x)), 0, _535 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    float3 param = world_pos;\n    float4 _615 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _458);\n    return int2(int(_615.x), int(_615.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_458.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2420 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _458);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2571 = fa_linear_to_srgb(param);\n        c = _2571;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2579 = fa_srgb_to_linear(param_1);\n            c = _2579;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _223;\n    if (bool(i.front_facing))\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = fast::normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _274 = fast::normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _277;\n    if (bool(i.front_facing))\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _458, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _458.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2610 = fa_tex_fix(param_2, param_3);\n    float4 _3645 = base_t;\n    _3645.x = _2610.x;\n    _3645.y = _2610.y;\n    _3645.z = _2610.z;\n    base_t = _3645;\n    float4 _2624 = (_3645 * _458.fa_base_color) * i.vertex_color;\n    float3 _3525 = i.world_normal;\n    if (_458.fa_maps.z > 0.5)\n    {\n        float param_4 = _458.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2656 = fa_tex_fix(param_6, param_7);\n        float3 _2659 = (_2656 * 2.0) - float3(1.0);\n        float2 _2664 = _2659.xy * _458.fa_maps.x;\n        float3 _3653 = _2659;\n        _3653.x = _2664.x;\n        _3653.y = _2664.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3653;\n        _3525 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _458.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2693 = fa_tex_fix(param_12, param_13);\n    float4 _3656 = mrt;\n    _3656.x = _2693.x;\n    _3656.y = _2693.y;\n    _3656.z = _2693.z;\n    mrt = _3656;\n    float4 _2721 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _458.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2721.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2733 = fa_tex_fix(param_16, param_17);\n    float param_18 = _458.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2763 = fa_tex_fix(param_20, param_21);\n    float _3530 = _458.fa_layers_a.x;\n    float _3531 = _458.fa_layers_a.y;\n    float _3534 = _458.fa_layers_a.z;\n    float _3533 = _458.fa_layers_b.w;\n    float _3536 = _458.fa_layers_c.x;\n    if (_458.fa_layers_c.z > 0.5)\n    {\n        if (mod(_458.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3530 *= _2733.y;\n            _3531 *= _2733.z;\n            _3533 *= _2721.w;\n        }\n        if (_458.fa_layers_c.z > 1.5)\n        {\n            _3534 *= mrt.x;\n            _3536 *= mrt.w;\n        }\n    }\n    return Surface{ _2624.xyz, _2624.w, _3525, fast::clamp(_458.fa_pbr.x * _2693.z, 0.0, 1.0), fast::clamp(_458.fa_pbr.y * _2693.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_458.fa_maps.y * (_2733.x - 1.0)), _458.fa_emissive.xyz + (_458.fa_model_emissive.xyz * _2763), _3530, _3531, _458.fa_layers_b.xyz, _3533, _3534, _458.fa_layers_a.w, _3536, _458.fa_layers_c.y, _458.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _696 = rect.zw - rect.xy;\n    float2 _700 = _696 * atlas;\n    float2 _704 = ddx * _700;\n    float2 _708 = ddy * _700;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _696)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _743 = _458.fa_counts.y < 0.5;\n    bool _750;\n    if (!_743)\n    {\n        _750 = _458.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    float3 _756 = dfdx(world_pos);\n    float3 _759 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _763 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _458);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(_458.fa_counts.y + 0.5);\n    int param_1 = _777;\n    float4 _781 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    float4 _793 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _794 = _793.x;\n    int _800 = int(_458.fa_counts.w + 0.5) - 1;\n    int _804 = int(_763.z);\n    float3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        float4 _840 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_840.w + 0.5) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        float4 _855 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _835 + 1;\n        float4 _860 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _835 + 2;\n        float4 _865 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        float3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        float3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = fast::clamp(dot(geo_normal, fast::normalize(_882)) * _840.z, 0.0, 1.0);\n        if (_923 <= 0.0)\n        {\n            continue;\n        }\n        float _943 = (fast::clamp((0.5 - abs(_887)) * 10.0, 0.0, 1.0) * _923) * _840.x;\n        float2 _951 = float2(_873 + 0.5, 0.5 - _880);\n        float2 _961 = float2(dot(_868, _756), dot(_875, _756));\n        float2 _971 = float2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        float4 _976 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _835 + 3;\n        float4 _981 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _835 + 4;\n        float4 _986 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            float4 param_11 = _981;\n            float2 param_12 = _951;\n            float2 param_13 = _784;\n            float2 param_14 = _961;\n            float2 param_15 = _971;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_794 > 0.5) && (_794 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1022 = fa_dc_to_linear(param_16);\n                float4 _3581 = tx;\n                _3581.x = _1022.x;\n                _3581.y = _1022.y;\n                _3581.z = _1022.z;\n                tx = _3581;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_943 * tex_a) * _976.w, 0.0, 1.0)));\n        if (_986.z > _986.x)\n        {\n            float4 param_17 = _986;\n            float2 param_18 = _951;\n            float2 param_19 = _784;\n            float2 param_20 = _961;\n            float2 param_21 = _971;\n            float4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_794 > 1.5)\n            {\n                float3 param_22 = _1066.xyz;\n                float3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            float3 _1086 = (_1070 * 2.0) - float3(1.0);\n            float2 _1091 = _1086.xy * _840.y;\n            float3 _1113 = (fast::normalize(_868) * _1091.x) + (fast::normalize(_875) * _1091.y);\n            float3 _1116 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1116, fast::normalize((_1116 * fast::max(_1086.z, 0.0500000007450580596923828125)) + (_1113 - (_1116 * dot(_1116, _1113)))), float3(fast::clamp(_943 * (_996 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_458.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2333 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2333;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_458.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _458, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _458.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _458, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    int param = (int(_458.fa_cl_info.x) + int(_458.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _458);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _333 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _339 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _342 = _339.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _348 = _342 < 0.5;\n    float3 l;\n    if (_348)\n    {\n        l = fast::normalize(_333.xyz);\n    }\n    else\n    {\n        float3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / float3(fast::max(_362, 9.9999997473787516355514526367188e-05));\n        float _377 = _362 / fast::max(_333.w, 0.001000000047497451305389404296875);\n        float _383 = fast::clamp(1.0 - (_377 * _377), 0.0, 1.0);\n        atten = _383 * _383;\n        if (_342 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _397 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_407, 1.0, 0.25);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, fast::normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _339.xyz * atten, atten, 1.0, dist, _444 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1198)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = _1198.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = _1198.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = _1198.fa_shadow_split.z;\n            }\n            else\n            {\n                _1212 = _1198.fa_shadow_split.w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1249;\n    if (conv.x < 0.5)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1295 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1309 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            float2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            float2 param_6 = uv + (_1328 * _1198.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        float2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1403 * _1198.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1384);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    float _1445 = fast::max(_1198.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1450 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1456 = sqrt(1.0 - (_1450 * _1450));\n    float _1463 = fast::min(_1456 / fast::max(_1450, 0.20000000298023223876953125), 4.0);\n    float _1468;\n    if (_1198.fa_shadow_bias.y > 0.0)\n    {\n        _1468 = _1198.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1468 = 1.5 * _1198.fa_shadow_info[ci].x;\n    }\n    float4 _1493 = _1198.fa_shadow_mat[ci] * float4(world + (n * (_1468 * _1456)), 1.0);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < _1198.fa_shadow_rect[ci].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > _1198.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < _1198.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > _1198.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0;\n    }\n    float _1546;\n    if (_1198.fa_shadow_bias.x > 0.0)\n    {\n        _1546 = _1198.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1546 = 1.5 * _1198.fa_shadow_info[ci].x;\n    }\n    float2 param = _1493.xy;\n    float4 param_1 = _1198.fa_shadow_rect[ci];\n    float param_2 = _1493.z - ((_1546 * (1.0 + (0.5 * _1463))) / _1445);\n    float param_3 = _1198.fa_shadow_info[ci].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25;\n    float param_6 = ((_1198.fa_shadow_info[ci].x * fast::min(_1463, 3.0)) * 0.5) / _1445;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1198.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1198.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    if (_458.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1973 = int(_1198.fa_shadow_cfg.x + 0.5);\n    if (_1973 < 1)\n    {\n        return 1.0;\n    }\n    float _1988 = dot(world - _1198.fa_shadow_eye.xyz, _1198.fa_shadow_fwd.xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param, _1198))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > _1198.fa_shadow_split.x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > _1198.fa_shadow_split.y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > _1198.fa_shadow_split.z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n        s = _2055;\n        if (_2055 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1198.fa_shadow_cfg.y > 0.0)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5, _1198);\n        }\n        else\n        {\n            _2080 = _1198.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2099 = _1198.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1198) - _2080, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2110 = fast::clamp((_1988 - (fa_shadow_split_at(param_7, _1198) - _2099)) / _2099, 0.0, 1.0);\n        if (_2110 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n                s2 = _2131;\n                if (_2131 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    bool _1604 = _458.fa_pbr.z < 0.5;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = _1198.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0;\n    }\n    int param = (int(_1198.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1625 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1635 = int(_1626 + 0.5);\n    int param_1 = _1635;\n    float4 _1639 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1635 + 1;\n    float4 _1644 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0)\n    {\n        float _1664 = 1.0 - smoothstep(0.75 * _1647, _1647, length(world - _1198.fa_shadow_eye.xyz));\n        fade = _1664;\n        if (_1664 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1683 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    float4 _1746 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1732 + 4;\n    float4 _1751 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1732 + 5;\n    float4 _1756 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1768 = _1756.x * fast::max(dot(_1746, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1773 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1796 = fast::clamp(dot(n, _1746.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1819 = fast::min(sqrt(1.0 - (_1796 * _1796)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1746, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5 * _1768;\n    }\n    float4 _1844 = float4(world + (n * (_1824 * sqrt(1.0 - (_1773 * _1773)))), 1.0);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0;\n    }\n    float2 _1866 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1844), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1844)) / float2(_1848);\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5 * _1768;\n    }\n    float2 param_10 = _1866;\n    float4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0 + (0.5 * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0;\n    float param_15 = _1756.z * 0.25;\n    float param_16 = (_1768 * fast::min(_1819, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5);\n    float param_19 = _1639.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2447 = fa_lm.z > 0.5;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3510 = _2476.direction;\n    float3 _3505 = _2476.color;\n    float _3512 = _2476.attenuation;\n    float _3507 = _2476.shadow;\n    int _3515 = _2476.type;\n    if ((_3515 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3510;\n        float _2490 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex, fa_world_pos);\n        _3507 = _2490;\n        _3505 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3515 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3512 > 0.0;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3510;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex);\n            _3507 = _2519;\n            _3505 *= _2519;\n        }\n    }\n    return LightSample{ _3510, _3505, _3512, _3507, _2476._distance, _3515 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1198)\n{\n    if (_1198.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2155 = int(_1198.fa_shadow_cfg.x + 0.5);\n    float _2165 = dot(world - _1198.fa_shadow_eye.xyz, _1198.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param, _1198);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > _1198.fa_shadow_split.x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > _1198.fa_shadow_split.y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > _1198.fa_shadow_split.z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _458 [[buffer(1)]], constant fa_shadows& _1198 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3321 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3321 = -_3321;\n    }\n    float3 _2906 = fast::normalize(_458.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _458, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n    Surface _2914 = fa_standard_surface(param_1, _458, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3360 = _2914.albedo;\n    float _3361 = _2914.alpha;\n    float3 _3362 = _2914.normal;\n    float _3363 = _2914.metallic;\n    float _3364 = _2914.roughness;\n    float _3365 = _2914.occlusion;\n    float3 _3366 = _2914.emission;\n    float _3367 = _2914.clearcoat;\n    float _3368 = _2914.clearcoat_roughness;\n    float3 _3369 = _2914.sheen_color;\n    float _3370 = _2914.sheen_roughness;\n    float _3371 = _2914.anisotropy;\n    float _3372 = _2914.anisotropy_rotation;\n    float _3373 = _2914.specular;\n    float _3374 = _2914.ior;\n    float3 _3375 = _2914.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n    Surface param_3 = _2914;\n    surface(param_2, param_3);\n    _3360 = param_3.albedo;\n    _3361 = param_3.alpha;\n    _3362 = param_3.normal;\n    _3363 = param_3.metallic;\n    _3364 = param_3.roughness;\n    _3365 = param_3.occlusion;\n    _3366 = param_3.emission;\n    _3367 = param_3.clearcoat;\n    _3368 = param_3.clearcoat_roughness;\n    _3369 = param_3.sheen_color;\n    _3370 = param_3.sheen_roughness;\n    _3371 = param_3.anisotropy;\n    _3372 = param_3.anisotropy_rotation;\n    _3373 = param_3.specular;\n    _3374 = param_3.ior;\n    _3375 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3321;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _458, fa_decal_tex, fa_env_smp);\n    _3360 = param_6;\n    _3362 = param_7;\n    float3 result;\n    if (_458.fa_emissive.w > 0.5)\n    {\n        result = _3360;\n    }\n    else\n    {\n        float3 _2952 = _3362;\n        float3 _2953 = fast::normalize(_2952);\n        _3362 = _2953;\n        float3 param_8 = _2953;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _458, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2972 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2972; ln++)\n        {\n            int param_12 = ln;\n            int _2985 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _458, fa_cl_ndir, fa_cl_slot);\n            bool _2988 = in.fa_lm.z > 0.5;\n            bool _2994;\n            if (_2988)\n            {\n                int param_13 = _2985;\n                _2994 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2994 = _2988;\n            }\n            if (_2994)\n            {\n                continue;\n            }\n            int param_14 = _2985;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3321;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3021 = result;\n    float3 _3022 = _3021 + _3366;\n    result = _3022;\n    float3 param_20 = _3022;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1198);\n    bool _3031 = _458.fa_fog.w > 0.0;\n    bool _3038;\n    if (!_3031)\n    {\n        _3038 = _458.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3038 = _3031;\n    }\n    if (_3038)\n    {\n        float3 _3047 = in.fa_world_pos - _458.fa_camera_pos.xyz;\n        float _3053 = dot(_3047, _458.fa_fog_c.xyz);\n        bool _3057 = _458.fa_fog_c.w > 0.5;\n        float _3058;\n        if (_3057)\n        {\n            _3058 = _3053;\n        }\n        else\n        {\n            _3058 = length(_3047);\n        }\n        float _3070 = _3058 - _458.fa_fog_b.x;\n        if (_3070 > 0.0)\n        {\n            float _3079 = _458.fa_fog.w * _3070;\n            float tau = _3079 * _3079;\n            if (_458.fa_fog_b.y > 0.0)\n            {\n                float _3095;\n                if (_3057)\n                {\n                    _3095 = in.fa_world_pos.y - (_458.fa_fog_c.y * _3053);\n                }\n                else\n                {\n                    _3095 = _458.fa_camera_pos.y;\n                }\n                float _3116 = mix(_3095, in.fa_world_pos.y, fast::clamp(_458.fa_fog_b.x / _3058, 0.0, 1.0));\n                float _3120 = in.fa_world_pos.y - _3116;\n                float _3125 = _3116 - _458.fa_fog_b.z;\n                float _3130 = in.fa_world_pos.y - _458.fa_fog_b.z;\n                bool _3133 = _3125 <= 0.0;\n                bool _3134 = !_3133;\n                bool _3140;\n                if (_3134)\n                {\n                    _3140 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3140 = _3133;\n                }\n                float _3141;\n                if (_3140)\n                {\n                    _3141 = _458.fa_fog_b.y;\n                }\n                else\n                {\n                    _3141 = _458.fa_fog_b.y * exp(-fast::min(_458.fa_fog_b.w * _3125, 80.0));\n                }\n                bool _3168;\n                if (_3134)\n                {\n                    _3168 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3168 = _3133;\n                }\n                float _3169;\n                if (_3168)\n                {\n                    _3169 = _458.fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3169 = (_458.fa_fog_b.y * (1.0 - exp(-fast::min(_458.fa_fog_b.w * _3125, 80.0)))) / _458.fa_fog_b.w;\n                }\n                bool _3194 = _3130 <= 0.0;\n                bool _3201;\n                if (!_3194)\n                {\n                    _3201 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3201 = _3194;\n                }\n                float _3202;\n                if (_3201)\n                {\n                    _3202 = _458.fa_fog_b.y * _3130;\n                }\n                else\n                {\n                    _3202 = (_458.fa_fog_b.y * (1.0 - exp(-fast::min(_458.fa_fog_b.w * _3130, 80.0)))) / _458.fa_fog_b.w;\n                }\n                float _3229;\n                if (abs(_3120) < 0.001000000047497451305389404296875)\n                {\n                    _3229 = _3141;\n                }\n                else\n                {\n                    _3229 = (_3202 - _3169) / _3120;\n                }\n                tau += (_3070 * fast::max(_3229, 0.0));\n            }\n            result = mix(result, _458.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3361);\n    return out;\n}\n\n",
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
            "inst_name": "_458",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1198",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    bool _463 = _458.fa_cl_info.x < 0.0;\n    bool _470;\n    if (!_463)\n    {\n        _470 = _458.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = _458.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = _458.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = _458.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return float4(0.0);\n    }\n    float4 _502 = float4(world_pos, 1.0);\n    float _509 = dot(_458.fa_cl_vpw, _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _531 = float2(dot(_458.fa_cl_vpx, _502), dot(_458.fa_cl_vpy, _502)) / float2(_509);\n    int _535 = int(_458.fa_cl_grid.x);\n    int _539 = int(_458.fa_cl_grid.y);\n    int param = (int(_458.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_458.fa_cl_fwd.xyz, world_pos) + _458.fa_cl_fwd.w, _458.fa_cl_grid.w) / _458.fa_cl_grid.w) * _458.fa_cl_grid.z)), 0, int(_458.fa_cl_info.y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5) + 0.5) * _458.fa_cl_grid.y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5) + 0.5) * _458.fa_cl_grid.x)), 0, _535 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    float3 param = world_pos;\n    float4 _615 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _458);\n    return int2(int(_615.x), int(_615.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_458.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2420 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _458);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2571 = fa_linear_to_srgb(param);\n        c = _2571;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2579 = fa_srgb_to_linear(param_1);\n            c = _2579;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _223;\n    if (bool(i.front_facing))\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    float3 _247 = fast::normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    float3 _274 = fast::normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    float3 _277;\n    if (bool(i.front_facing))\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _458, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _458.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2610 = fa_tex_fix(param_2, param_3);\n    float4 _3645 = base_t;\n    _3645.x = _2610.x;\n    _3645.y = _2610.y;\n    _3645.z = _2610.z;\n    base_t = _3645;\n    float4 _2624 = (_3645 * _458.fa_base_color) * i.vertex_color;\n    float3 _3525 = i.world_normal;\n    if (_458.fa_maps.z > 0.5)\n    {\n        float param_4 = _458.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2656 = fa_tex_fix(param_6, param_7);\n        float3 _2659 = (_2656 * 2.0) - float3(1.0);\n        float2 _2664 = _2659.xy * _458.fa_maps.x;\n        float3 _3653 = _2659;\n        _3653.x = _2664.x;\n        _3653.y = _2664.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3653;\n        _3525 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _458.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2693 = fa_tex_fix(param_12, param_13);\n    float4 _3656 = mrt;\n    _3656.x = _2693.x;\n    _3656.y = _2693.y;\n    _3656.z = _2693.z;\n    mrt = _3656;\n    float4 _2721 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _458.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2721.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2733 = fa_tex_fix(param_16, param_17);\n    float param_18 = _458.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2763 = fa_tex_fix(param_20, param_21);\n    float _3530 = _458.fa_layers_a.x;\n    float _3531 = _458.fa_layers_a.y;\n    float _3534 = _458.fa_layers_a.z;\n    float _3533 = _458.fa_layers_b.w;\n    float _3536 = _458.fa_layers_c.x;\n    if (_458.fa_layers_c.z > 0.5)\n    {\n        if (mod(_458.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3530 *= _2733.y;\n            _3531 *= _2733.z;\n            _3533 *= _2721.w;\n        }\n        if (_458.fa_layers_c.z > 1.5)\n        {\n            _3534 *= mrt.x;\n            _3536 *= mrt.w;\n        }\n    }\n    return Surface{ _2624.xyz, _2624.w, _3525, fast::clamp(_458.fa_pbr.x * _2693.z, 0.0, 1.0), fast::clamp(_458.fa_pbr.y * _2693.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_458.fa_maps.y * (_2733.x - 1.0)), _458.fa_emissive.xyz + (_458.fa_model_emissive.xyz * _2763), _3530, _3531, _458.fa_layers_b.xyz, _3533, _3534, _458.fa_layers_a.w, _3536, _458.fa_layers_c.y, _458.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _696 = rect.zw - rect.xy;\n    float2 _700 = _696 * atlas;\n    float2 _704 = ddx * _700;\n    float2 _708 = ddy * _700;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _696)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _743 = _458.fa_counts.y < 0.5;\n    bool _750;\n    if (!_743)\n    {\n        _750 = _458.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    float3 _756 = dfdx(world_pos);\n    float3 _759 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _763 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _458);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(_458.fa_counts.y + 0.5);\n    int param_1 = _777;\n    float4 _781 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    float4 _793 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _794 = _793.x;\n    int _800 = int(_458.fa_counts.w + 0.5) - 1;\n    int _804 = int(_763.z);\n    float3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        float4 _840 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_840.w + 0.5) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        float4 _855 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _835 + 1;\n        float4 _860 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _835 + 2;\n        float4 _865 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        float3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        float3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = fast::clamp(dot(geo_normal, fast::normalize(_882)) * _840.z, 0.0, 1.0);\n        if (_923 <= 0.0)\n        {\n            continue;\n        }\n        float _943 = (fast::clamp((0.5 - abs(_887)) * 10.0, 0.0, 1.0) * _923) * _840.x;\n        float2 _951 = float2(_873 + 0.5, 0.5 - _880);\n        float2 _961 = float2(dot(_868, _756), dot(_875, _756));\n        float2 _971 = float2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        float4 _976 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _835 + 3;\n        float4 _981 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _835 + 4;\n        float4 _986 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            float4 param_11 = _981;\n            float2 param_12 = _951;\n            float2 param_13 = _784;\n            float2 param_14 = _961;\n            float2 param_15 = _971;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_794 > 0.5) && (_794 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1022 = fa_dc_to_linear(param_16);\n                float4 _3581 = tx;\n                _3581.x = _1022.x;\n                _3581.y = _1022.y;\n                _3581.z = _1022.z;\n                tx = _3581;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_943 * tex_a) * _976.w, 0.0, 1.0)));\n        if (_986.z > _986.x)\n        {\n            float4 param_17 = _986;\n            float2 param_18 = _951;\n            float2 param_19 = _784;\n            float2 param_20 = _961;\n            float2 param_21 = _971;\n            float4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_794 > 1.5)\n            {\n                float3 param_22 = _1066.xyz;\n                float3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            float3 _1086 = (_1070 * 2.0) - float3(1.0);\n            float2 _1091 = _1086.xy * _840.y;\n            float3 _1113 = (fast::normalize(_868) * _1091.x) + (fast::normalize(_875) * _1091.y);\n            float3 _1116 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1116, fast::normalize((_1116 * fast::max(_1086.z, 0.0500000007450580596923828125)) + (_1113 - (_1116 * dot(_1116, _1113)))), float3(fast::clamp(_943 * (_996 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_458.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2333 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2333;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_458.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _458, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _458.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _458, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _458, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458)\n{\n    int param = (int(_458.fa_cl_info.x) + int(_458.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _458);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _333 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _339 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _342 = _339.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _348 = _342 < 0.5;\n    float3 l;\n    if (_348)\n    {\n        l = fast::normalize(_333.xyz);\n    }\n    else\n    {\n        float3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / float3(fast::max(_362, 9.9999997473787516355514526367188e-05));\n        float _377 = _362 / fast::max(_333.w, 0.001000000047497451305389404296875);\n        float _383 = fast::clamp(1.0 - (_377 * _377), 0.0, 1.0);\n        atten = _383 * _383;\n        if (_342 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _397 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_407, 1.0, 0.25);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, fast::normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _339.xyz * atten, atten, 1.0, dist, _444 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1198)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = _1198.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = _1198.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = _1198.fa_shadow_split.z;\n            }\n            else\n            {\n                _1212 = _1198.fa_shadow_split.w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1249;\n    if (conv.x < 0.5)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1295 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1309 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            float2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            float2 param_6 = uv + (_1328 * _1198.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        float2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1403 * _1198.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1384);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    float _1445 = fast::max(_1198.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1450 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1456 = sqrt(1.0 - (_1450 * _1450));\n    float _1463 = fast::min(_1456 / fast::max(_1450, 0.20000000298023223876953125), 4.0);\n    float _1468;\n    if (_1198.fa_shadow_bias.y > 0.0)\n    {\n        _1468 = _1198.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1468 = 1.5 * _1198.fa_shadow_info[ci].x;\n    }\n    float4 _1493 = _1198.fa_shadow_mat[ci] * float4(world + (n * (_1468 * _1456)), 1.0);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < _1198.fa_shadow_rect[ci].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > _1198.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < _1198.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > _1198.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0;\n    }\n    float _1546;\n    if (_1198.fa_shadow_bias.x > 0.0)\n    {\n        _1546 = _1198.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1546 = 1.5 * _1198.fa_shadow_info[ci].x;\n    }\n    float2 param = _1493.xy;\n    float4 param_1 = _1198.fa_shadow_rect[ci];\n    float param_2 = _1493.z - ((_1546 * (1.0 + (0.5 * _1463))) / _1445);\n    float param_3 = _1198.fa_shadow_info[ci].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25;\n    float param_6 = ((_1198.fa_shadow_info[ci].x * fast::min(_1463, 3.0)) * 0.5) / _1445;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1198.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1198.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    if (_458.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1973 = int(_1198.fa_shadow_cfg.x + 0.5);\n    if (_1973 < 1)\n    {\n        return 1.0;\n    }\n    float _1988 = dot(world - _1198.fa_shadow_eye.xyz, _1198.fa_shadow_fwd.xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param, _1198))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > _1198.fa_shadow_split.x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > _1198.fa_shadow_split.y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > _1198.fa_shadow_split.z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n        s = _2055;\n        if (_2055 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1198.fa_shadow_cfg.y > 0.0)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5, _1198);\n        }\n        else\n        {\n            _2080 = _1198.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2099 = _1198.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1198) - _2080, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2110 = fast::clamp((_1988 - (fa_shadow_split_at(param_7, _1198) - _2099)) / _2099, 0.0, 1.0);\n        if (_2110 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex);\n                s2 = _2131;\n                if (_2131 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex)\n{\n    bool _1604 = _458.fa_pbr.z < 0.5;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = _1198.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0;\n    }\n    int param = (int(_1198.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1625 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1635 = int(_1626 + 0.5);\n    int param_1 = _1635;\n    float4 _1639 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1635 + 1;\n    float4 _1644 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0)\n    {\n        float _1664 = 1.0 - smoothstep(0.75 * _1647, _1647, length(world - _1198.fa_shadow_eye.xyz));\n        fade = _1664;\n        if (_1664 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1683 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    float4 _1746 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1732 + 4;\n    float4 _1751 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1732 + 5;\n    float4 _1756 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1768 = _1756.x * fast::max(dot(_1746, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1773 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1796 = fast::clamp(dot(n, _1746.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1819 = fast::min(sqrt(1.0 - (_1796 * _1796)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1746, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5 * _1768;\n    }\n    float4 _1844 = float4(world + (n * (_1824 * sqrt(1.0 - (_1773 * _1773)))), 1.0);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0;\n    }\n    float2 _1866 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1844), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1844)) / float2(_1848);\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5 * _1768;\n    }\n    float2 param_10 = _1866;\n    float4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0 + (0.5 * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0;\n    float param_15 = _1756.z * 0.25;\n    float param_16 = (_1768 * fast::min(_1819, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5);\n    float param_19 = _1639.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1198, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _458, thread float4& gl_FragCoord, constant fa_shadows& _1198, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2447 = fa_lm.z > 0.5;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3510 = _2476.direction;\n    float3 _3505 = _2476.color;\n    float _3512 = _2476.attenuation;\n    float _3507 = _2476.shadow;\n    int _3515 = _2476.type;\n    if ((_3515 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3510;\n        float _2490 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex, fa_world_pos);\n        _3507 = _2490;\n        _3505 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3515 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3512 > 0.0;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3510;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex);\n            _3507 = _2519;\n            _3505 *= _2519;\n        }\n    }\n    return LightSample{ _3510, _3505, _3512, _3507, _2476._distance, _3515 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1198)\n{\n    if (_1198.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2155 = int(_1198.fa_shadow_cfg.x + 0.5);\n    float _2165 = dot(world - _1198.fa_shadow_eye.xyz, _1198.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param, _1198);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > _1198.fa_shadow_split.x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > _1198.fa_shadow_split.y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > _1198.fa_shadow_split.z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _458 [[buffer(1)]], constant fa_shadows& _1198 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3321 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3321 = -_3321;\n    }\n    float3 _2906 = fast::normalize(_458.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _458, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n    Surface _2914 = fa_standard_surface(param_1, _458, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3360 = _2914.albedo;\n    float _3361 = _2914.alpha;\n    float3 _3362 = _2914.normal;\n    float _3363 = _2914.metallic;\n    float _3364 = _2914.roughness;\n    float _3365 = _2914.occlusion;\n    float3 _3366 = _2914.emission;\n    float _3367 = _2914.clearcoat;\n    float _3368 = _2914.clearcoat_roughness;\n    float3 _3369 = _2914.sheen_color;\n    float _3370 = _2914.sheen_roughness;\n    float _3371 = _2914.anisotropy;\n    float _3372 = _2914.anisotropy_rotation;\n    float _3373 = _2914.specular;\n    float _3374 = _2914.ior;\n    float3 _3375 = _2914.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n    Surface param_3 = _2914;\n    surface(param_2, param_3);\n    _3360 = param_3.albedo;\n    _3361 = param_3.alpha;\n    _3362 = param_3.normal;\n    _3363 = param_3.metallic;\n    _3364 = param_3.roughness;\n    _3365 = param_3.occlusion;\n    _3366 = param_3.emission;\n    _3367 = param_3.clearcoat;\n    _3368 = param_3.clearcoat_roughness;\n    _3369 = param_3.sheen_color;\n    _3370 = param_3.sheen_roughness;\n    _3371 = param_3.anisotropy;\n    _3372 = param_3.anisotropy_rotation;\n    _3373 = param_3.specular;\n    _3374 = param_3.ior;\n    _3375 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3321;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _458, fa_decal_tex, fa_env_smp);\n    _3360 = param_6;\n    _3362 = param_7;\n    float3 result;\n    if (_458.fa_emissive.w > 0.5)\n    {\n        result = _3360;\n    }\n    else\n    {\n        float3 _2952 = _3362;\n        float3 _2953 = fast::normalize(_2952);\n        _3362 = _2953;\n        float3 param_8 = _2953;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _458, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2972 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2972; ln++)\n        {\n            int param_12 = ln;\n            int _2985 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _458, fa_cl_ndir, fa_cl_slot);\n            bool _2988 = in.fa_lm.z > 0.5;\n            bool _2994;\n            if (_2988)\n            {\n                int param_13 = _2985;\n                _2994 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2994 = _2988;\n            }\n            if (_2994)\n            {\n                continue;\n            }\n            int param_14 = _2985;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3321;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3321, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2906, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3360, _3361, _3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _458, gl_FragCoord, _1198, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3021 = result;\n    float3 _3022 = _3021 + _3366;\n    result = _3022;\n    float3 param_20 = _3022;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1198);\n    bool _3031 = _458.fa_fog.w > 0.0;\n    bool _3038;\n    if (!_3031)\n    {\n        _3038 = _458.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3038 = _3031;\n    }\n    if (_3038)\n    {\n        float3 _3047 = in.fa_world_pos - _458.fa_camera_pos.xyz;\n        float _3053 = dot(_3047, _458.fa_fog_c.xyz);\n        bool _3057 = _458.fa_fog_c.w > 0.5;\n        float _3058;\n        if (_3057)\n        {\n            _3058 = _3053;\n        }\n        else\n        {\n            _3058 = length(_3047);\n        }\n        float _3070 = _3058 - _458.fa_fog_b.x;\n        if (_3070 > 0.0)\n        {\n            float _3079 = _458.fa_fog.w * _3070;\n            float tau = _3079 * _3079;\n            if (_458.fa_fog_b.y > 0.0)\n            {\n                float _3095;\n                if (_3057)\n                {\n                    _3095 = in.fa_world_pos.y - (_458.fa_fog_c.y * _3053);\n                }\n                else\n                {\n                    _3095 = _458.fa_camera_pos.y;\n                }\n                float _3116 = mix(_3095, in.fa_world_pos.y, fast::clamp(_458.fa_fog_b.x / _3058, 0.0, 1.0));\n                float _3120 = in.fa_world_pos.y - _3116;\n                float _3125 = _3116 - _458.fa_fog_b.z;\n                float _3130 = in.fa_world_pos.y - _458.fa_fog_b.z;\n                bool _3133 = _3125 <= 0.0;\n                bool _3134 = !_3133;\n                bool _3140;\n                if (_3134)\n                {\n                    _3140 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3140 = _3133;\n                }\n                float _3141;\n                if (_3140)\n                {\n                    _3141 = _458.fa_fog_b.y;\n                }\n                else\n                {\n                    _3141 = _458.fa_fog_b.y * exp(-fast::min(_458.fa_fog_b.w * _3125, 80.0));\n                }\n                bool _3168;\n                if (_3134)\n                {\n                    _3168 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3168 = _3133;\n                }\n                float _3169;\n                if (_3168)\n                {\n                    _3169 = _458.fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3169 = (_458.fa_fog_b.y * (1.0 - exp(-fast::min(_458.fa_fog_b.w * _3125, 80.0)))) / _458.fa_fog_b.w;\n                }\n                bool _3194 = _3130 <= 0.0;\n                bool _3201;\n                if (!_3194)\n                {\n                    _3201 = _458.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3201 = _3194;\n                }\n                float _3202;\n                if (_3201)\n                {\n                    _3202 = _458.fa_fog_b.y * _3130;\n                }\n                else\n                {\n                    _3202 = (_458.fa_fog_b.y * (1.0 - exp(-fast::min(_458.fa_fog_b.w * _3130, 80.0)))) / _458.fa_fog_b.w;\n                }\n                float _3229;\n                if (abs(_3120) < 0.001000000047497451305389404296875)\n                {\n                    _3229 = _3141;\n                }\n                else\n                {\n                    _3229 = (_3202 - _3169) / _3120;\n                }\n                tau += (_3070 * fast::max(_3229, 0.0));\n            }\n            result = mix(result, _458.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3361);\n    return out;\n}\n\n",
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
            "inst_name": "_458",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1198",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
