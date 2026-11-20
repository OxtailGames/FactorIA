{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "metal_macos",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _145)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _45)\n{\n    v.world_pos += float3(_45.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _45, constant fa_mesh_vs_params& _145, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _145);\n    vertex0(param_6, _45);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _145.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _145 [[buffer(0)]], constant fa_material_vs& _45 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _45, _145, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    bool _415 = _410.fa_cl_info.x < 0.0;\n    bool _422;\n    if (!_415)\n    {\n        _422 = _410.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = _410.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = _410.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = _410.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return float4(0.0);\n    }\n    float4 _454 = float4(world_pos, 1.0);\n    float _461 = dot(_410.fa_cl_vpw, _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _483 = float2(dot(_410.fa_cl_vpx, _454), dot(_410.fa_cl_vpy, _454)) / float2(_461);\n    int _487 = int(_410.fa_cl_grid.x);\n    int _491 = int(_410.fa_cl_grid.y);\n    int param = (int(_410.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_410.fa_cl_fwd.xyz, world_pos) + _410.fa_cl_fwd.w, _410.fa_cl_grid.w) / _410.fa_cl_grid.w) * _410.fa_cl_grid.z)), 0, int(_410.fa_cl_info.y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5) + 0.5) * _410.fa_cl_grid.y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5) + 0.5) * _410.fa_cl_grid.x)), 0, _487 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    float3 param = world_pos;\n    float4 _567 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _410);\n    return int2(int(_567.x), int(_567.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_410.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1965 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _410);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2054 = fa_linear_to_srgb(param);\n        c = _2054;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2062 = fa_srgb_to_linear(param_1);\n            c = _2062;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _182;\n    if (bool(i.front_facing))\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    float3 _206 = fast::normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    float3 _234 = fast::normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    float3 _237;\n    if (bool(i.front_facing))\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _410, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _410.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2093 = fa_tex_fix(param_2, param_3);\n    float4 _2941 = base_t;\n    _2941.x = _2093.x;\n    _2941.y = _2093.y;\n    _2941.z = _2093.z;\n    base_t = _2941;\n    float4 _2107 = (_2941 * _410.fa_base_color) * i.vertex_color;\n    float3 _2865 = i.world_normal;\n    if (_410.fa_maps.z > 0.5)\n    {\n        float param_4 = _410.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2139 = fa_tex_fix(param_6, param_7);\n        float3 _2142 = (_2139 * 2.0) - float3(1.0);\n        float2 _2147 = _2142.xy * _410.fa_maps.x;\n        float3 _2949 = _2142;\n        _2949.x = _2147.x;\n        _2949.y = _2147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2949;\n        _2865 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _410.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2176 = fa_tex_fix(param_12, param_13);\n    float4 _2952 = mrt;\n    _2952.x = _2176.x;\n    _2952.y = _2176.y;\n    _2952.z = _2176.z;\n    mrt = _2952;\n    float param_14 = _410.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2215 = fa_tex_fix(param_16, param_17);\n    float param_18 = _410.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2242 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2107.xyz, _2107.w, _2865, fast::clamp(_410.fa_pbr.x * _2176.z, 0.0, 1.0), fast::clamp(_410.fa_pbr.y * _2176.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_410.fa_maps.y * (_2215.x - 1.0)), _410.fa_emissive.xyz + (_410.fa_model_emissive.xyz * _2242) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _648 = rect.zw - rect.xy;\n    float2 _652 = _648 * atlas;\n    float2 _656 = ddx * _652;\n    float2 _660 = ddy * _652;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _648)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _695 = dfdx(world_pos);\n    float3 _698 = dfdy(world_pos);\n    bool _701 = _410.fa_counts.y < 0.5;\n    bool _708;\n    if (!_701)\n    {\n        _708 = _410.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _715 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _410);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(_410.fa_counts.y + 0.5);\n    int param_1 = _729;\n    float4 _733 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    float4 _745 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _746 = _745.x;\n    int _752 = int(_410.fa_counts.w + 0.5) - 1;\n    int _756 = int(_715.z);\n    float3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        float4 _792 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_792.w + 0.5) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        float4 _807 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _787 + 1;\n        float4 _812 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _787 + 2;\n        float4 _817 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        float3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        float3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = fast::clamp(dot(geo_normal, fast::normalize(_834)) * _792.z, 0.0, 1.0);\n        if (_875 <= 0.0)\n        {\n            continue;\n        }\n        float _895 = (fast::clamp((0.5 - abs(_839)) * 10.0, 0.0, 1.0) * _875) * _792.x;\n        float2 _903 = float2(_825 + 0.5, 0.5 - _832);\n        float2 _913 = float2(dot(_820, _695), dot(_827, _695));\n        float2 _923 = float2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        float4 _928 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _787 + 3;\n        float4 _933 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _787 + 4;\n        float4 _938 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            float4 param_11 = _933;\n            float2 param_12 = _903;\n            float2 param_13 = _736;\n            float2 param_14 = _913;\n            float2 param_15 = _923;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_746 > 0.5) && (_746 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _974 = fa_dc_to_linear(param_16);\n                float4 _2903 = tx;\n                _2903.x = _974.x;\n                _2903.y = _974.y;\n                _2903.z = _974.z;\n                tx = _2903;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_895 * tex_a) * _928.w, 0.0, 1.0)));\n        if (_938.z > _938.x)\n        {\n            float4 param_17 = _938;\n            float2 param_18 = _903;\n            float2 param_19 = _736;\n            float2 param_20 = _913;\n            float2 param_21 = _923;\n            float4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_746 > 1.5)\n            {\n                float3 param_22 = _1018.xyz;\n                float3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            float3 _1038 = (_1022 * 2.0) - float3(1.0);\n            float2 _1043 = _1038.xy * _792.y;\n            float3 _1065 = (fast::normalize(_820) * _1043.x) + (fast::normalize(_827) * _1043.y);\n            float3 _1068 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1068, fast::normalize((_1068 * fast::max(_1038.z, 0.0500000007450580596923828125)) + (_1065 - (_1068 * dot(_1068, _1065)))), float3(fast::clamp(_895 * (_948 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_410.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _410.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    int param = (int(_410.fa_cl_info.x) + int(_410.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _410);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _282 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _288 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _291 = _288.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _298 = _291 < 0.5;\n    float3 l;\n    if (_298)\n    {\n        l = fast::normalize(_282.xyz);\n    }\n    else\n    {\n        float3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / float3(fast::max(_312, 9.9999997473787516355514526367188e-05));\n        float _327 = _312 / fast::max(_282.w, 0.001000000047497451305389404296875);\n        float _333 = fast::clamp(1.0 - (_327 * _327), 0.0, 1.0);\n        atten = _333 * _333;\n        if (_291 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _347 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            float4 _364 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5)\n            {\n                cos_inner = mix(_357, 1.0, 0.25);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, fast::normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _288.xyz * atten, atten, 1.0, dist, _396 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1150)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = _1150.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = _1150.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = _1150.fa_shadow_split.z;\n            }\n            else\n            {\n                _1164 = _1150.fa_shadow_split.w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex)\n{\n    float _1202 = fast::max(_1150.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1207 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1220 = fast::min(_1213 / fast::max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1225;\n    if (_1150.fa_shadow_bias.y > 0.0)\n    {\n        _1225 = _1150.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1225 = 1.5 * _1150.fa_shadow_info[ci].x;\n    }\n    float4 _1250 = _1150.fa_shadow_mat[ci] * float4(world + (n * (_1225 * _1213)), 1.0);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < _1150.fa_shadow_rect[ci].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > _1150.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < _1150.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > _1150.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0;\n    }\n    float _1303;\n    if (_1150.fa_shadow_bias.x > 0.0)\n    {\n        _1303 = _1150.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1303 = 1.5 * _1150.fa_shadow_info[ci].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0 + (0.5 * _1220))) / _1202);\n    float _1331 = ((_1150.fa_shadow_info[ci].x * fast::min(_1220, 3.0)) * 0.5) / _1202;\n    int _1340 = int(_1150.fa_shadow_cfg.z + 0.5);\n    if (_1340 == 1)\n    {\n        float2 param = _1250.xy;\n        float4 param_1 = _1150.fa_shadow_rect[ci];\n        float _1351 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = fast::clamp(((_1150.fa_shadow_cfg.w * _1202) * 0.25) / _1150.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            float2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            float2 param_5 = _1250.xy + (_1394 * _1150.fa_shadow_bias.zw);\n            float4 param_6 = _1150.fa_shadow_rect[ci];\n            float _1405 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1322 - (sum / cnt), 0.0) * _1202) * _1150.fa_shadow_cfg.w) / _1150.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        float2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1250.xy + (_1468 * _1150.fa_shadow_bias.zw);\n        float4 param_11 = _1150.fa_shadow_rect[ci];\n        float _1479 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex)\n{\n    if (_410.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1509 = int(_1150.fa_shadow_cfg.x + 0.5);\n    if (_1509 < 1)\n    {\n        return 1.0;\n    }\n    float _1524 = dot(world - _1150.fa_shadow_eye.xyz, _1150.fa_shadow_fwd.xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param, _1150))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > _1150.fa_shadow_split.x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > _1150.fa_shadow_split.y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > _1150.fa_shadow_split.z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1150, fa_shadow_tex);\n        s = _1591;\n        if (_1591 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1150.fa_shadow_cfg.y > 0.0)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5, _1150);\n        }\n        else\n        {\n            _1616 = _1150.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1635 = _1150.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1150) - _1616, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1646 = fast::clamp((_1524 - (fa_shadow_split_at(param_7, _1150) - _1635)) / _1635, 0.0, 1.0);\n        if (_1646 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1150, fa_shadow_tex);\n                s2 = _1667;\n                if (_1667 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2850 = _1993.direction;\n    float3 _2845 = _1993.color;\n    float _2847 = _1993.shadow;\n    int _2855 = _1993.type;\n    if ((_2855 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2850;\n        float _2007 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex, fa_world_pos);\n        _2847 = _2007;\n        _2845 *= _2007;\n    }\n    return LightSample{ _2850, _2845, _1993.attenuation, _2847, _1993._distance, _2855 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1897 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1900 = _1897.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1900 * _1900, exp2((-9.27999973297119140625) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_410.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _410.fa_env_horizon.w)).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625 * _1803;\n    return mix(mix(_410.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_410.fa_env_horizon.xyz, _410.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1803)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1833, 0.0500000007450580596923828125 + _1833, d.y))), ((_410.fa_env_sky.xyz + _410.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1803 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1939 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _410, fa_env_smp, fa_env_tex) * ((f0 * _1939.x) + float3(_1939.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1150)\n{\n    if (_1150.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1691 = int(_1150.fa_shadow_cfg.x + 0.5);\n    float _1701 = dot(world - _1150.fa_shadow_eye.xyz, _1150.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param, _1150);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > _1150.fa_shadow_split.x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > _1150.fa_shadow_split.y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > _1150.fa_shadow_split.z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _410 [[buffer(1)]], constant fa_shadows& _1150 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2770 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2770 = -_2770;\n    }\n    float3 _2285 = fast::normalize(_410.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _410, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2770, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2285, short(gl_FrontFacing) };\n    Surface _2293 = fa_standard_surface(param_1, _410, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2793 = _2293.albedo;\n    float _2794 = _2293.alpha;\n    float3 _2795 = _2293.normal;\n    float _2796 = _2293.metallic;\n    float _2797 = _2293.roughness;\n    float _2798 = _2293.occlusion;\n    float3 _2799 = _2293.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2770, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2285, short(gl_FrontFacing) };\n    Surface param_3 = _2293;\n    surface(param_2, param_3);\n    _2793 = param_3.albedo;\n    _2794 = param_3.alpha;\n    _2795 = param_3.normal;\n    _2796 = param_3.metallic;\n    _2797 = param_3.roughness;\n    _2798 = param_3.occlusion;\n    _2799 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2770;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _410, fa_decal_tex, fa_env_smp);\n    _2793 = param_6;\n    _2795 = param_7;\n    float3 result;\n    if (_410.fa_emissive.w > 0.5)\n    {\n        result = _2793;\n    }\n    else\n    {\n        float3 _2332 = fast::normalize(_2795);\n        float _2339 = fast::clamp(_2796, 0.0, 1.0);\n        float _2343 = fast::clamp(_2797, 0.0500000007450580596923828125, 1.0);\n        float _2347 = _2343 * _2343;\n        float _2351 = _2347 * _2347;\n        float _2356 = fast::max(dot(_2332, _2285), 9.9999997473787516355514526367188e-05);\n        float3 _2362 = _2793 * (1.0 - _2339);\n        float3 _2370 = mix(float3(0.039999999105930328369140625), _2793, float3(_2339));\n        float3 param_8 = _2332;\n        float3 lit = (fa_ambient_light(param_8, _410, fa_env_smp, fa_irr_tex) * _2362) * _2798;\n        int _2383 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2383; ln++)\n        {\n            int param_9 = ln;\n            int _2396 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _410, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _2396;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2770;\n            LightSample _2405 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex, in.fa_world_pos);\n            float3 _2828 = _2405.direction;\n            float _2413 = fast::max(dot(_2332, _2828), 0.0);\n            float3 _2424 = fast::normalize(_2828 + _2285);\n            float _2429 = fast::max(dot(_2332, _2424), 0.0);\n            float _2442 = ((_2429 * _2429) * (_2351 - 1.0)) + 1.0;\n            int param_13 = _2396;\n            lit += (((_2362 + (((_2370 + ((float3(1.0) - _2370) * powr(1.0 - fast::max(dot(_2285, _2424), 0.0), 5.0))) * (((_2351 / ((3.1415927410125732421875 * _2442) * _2442)) * (0.5 / fast::max(mix((2.0 * _2413) * _2356, _2413 + _2356, _2347), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2413))) * fa_light_rgb(param_13, fa_light_tex, fa_shadow_smp)) * (_2413 * (_2405.attenuation * _2405.shadow)));\n        }\n        float3 param_14 = _2332;\n        float3 param_15 = _2285;\n        float3 param_16 = _2370;\n        float param_17 = _2343;\n        float3 _2511 = lit;\n        float3 _2512 = _2511 + (fa_sky_reflection(param_14, param_15, param_16, param_17, _410, fa_env_smp, fa_env_tex) * _2798);\n        lit = _2512;\n        result = _2512;\n    }\n    float3 _2516 = result;\n    float3 _2517 = _2516 + _2799;\n    result = _2517;\n    float3 param_18 = _2517;\n    float3 param_19 = in.fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19, _1150);\n    bool _2526 = _410.fa_fog.w > 0.0;\n    bool _2534;\n    if (!_2526)\n    {\n        _2534 = _410.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2534 = _2526;\n    }\n    if (_2534)\n    {\n        float3 _2543 = in.fa_world_pos - _410.fa_camera_pos.xyz;\n        float _2550 = dot(_2543, _410.fa_fog_c.xyz);\n        bool _2554 = _410.fa_fog_c.w > 0.5;\n        float _2555;\n        if (_2554)\n        {\n            _2555 = _2550;\n        }\n        else\n        {\n            _2555 = length(_2543);\n        }\n        float _2567 = _2555 - _410.fa_fog_b.x;\n        if (_2567 > 0.0)\n        {\n            float _2576 = _410.fa_fog.w * _2567;\n            float tau = _2576 * _2576;\n            if (_410.fa_fog_b.y > 0.0)\n            {\n                float _2592;\n                if (_2554)\n                {\n                    _2592 = in.fa_world_pos.y - (_410.fa_fog_c.y * _2550);\n                }\n                else\n                {\n                    _2592 = _410.fa_camera_pos.y;\n                }\n                float _2613 = mix(_2592, in.fa_world_pos.y, fast::clamp(_410.fa_fog_b.x / _2555, 0.0, 1.0));\n                float _2617 = in.fa_world_pos.y - _2613;\n                float _2622 = _2613 - _410.fa_fog_b.z;\n                float _2627 = in.fa_world_pos.y - _410.fa_fog_b.z;\n                bool _2630 = _2622 <= 0.0;\n                bool _2631 = !_2630;\n                bool _2637;\n                if (_2631)\n                {\n                    _2637 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2637 = _2630;\n                }\n                float _2638;\n                if (_2637)\n                {\n                    _2638 = _410.fa_fog_b.y;\n                }\n                else\n                {\n                    _2638 = _410.fa_fog_b.y * exp(-fast::min(_410.fa_fog_b.w * _2622, 80.0));\n                }\n                bool _2665;\n                if (_2631)\n                {\n                    _2665 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2665 = _2630;\n                }\n                float _2666;\n                if (_2665)\n                {\n                    _2666 = _410.fa_fog_b.y * _2622;\n                }\n                else\n                {\n                    _2666 = (_410.fa_fog_b.y * (1.0 - exp(-fast::min(_410.fa_fog_b.w * _2622, 80.0)))) / _410.fa_fog_b.w;\n                }\n                bool _2691 = _2627 <= 0.0;\n                bool _2698;\n                if (!_2691)\n                {\n                    _2698 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2698 = _2691;\n                }\n                float _2699;\n                if (_2698)\n                {\n                    _2699 = _410.fa_fog_b.y * _2627;\n                }\n                else\n                {\n                    _2699 = (_410.fa_fog_b.y * (1.0 - exp(-fast::min(_410.fa_fog_b.w * _2627, 80.0)))) / _410.fa_fog_b.w;\n                }\n                float _2726;\n                if (abs(_2617) < 0.001000000047497451305389404296875)\n                {\n                    _2726 = _2638;\n                }\n                else\n                {\n                    _2726 = (_2699 - _2666) / _2617;\n                }\n                tau += (_2567 * fast::max(_2726, 0.0));\n            }\n            result = mix(result, _410.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2794);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _197)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_197.fa_joint_rows[_188] * weights[i]);\n        r1 += (_197.fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197.fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _150)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _50)\n{\n    v.world_pos += float3(_50.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _50, constant fa_mesh_vs_params& _150, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _150);\n    vertex0(param_6, _50);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _150.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _150 [[buffer(0)]], constant fa_skin& _197 [[buffer(3)]], constant fa_material_vs& _50 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _197);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _50, _150, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    bool _415 = _410.fa_cl_info.x < 0.0;\n    bool _422;\n    if (!_415)\n    {\n        _422 = _410.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = _410.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = _410.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = _410.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return float4(0.0);\n    }\n    float4 _454 = float4(world_pos, 1.0);\n    float _461 = dot(_410.fa_cl_vpw, _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _483 = float2(dot(_410.fa_cl_vpx, _454), dot(_410.fa_cl_vpy, _454)) / float2(_461);\n    int _487 = int(_410.fa_cl_grid.x);\n    int _491 = int(_410.fa_cl_grid.y);\n    int param = (int(_410.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_410.fa_cl_fwd.xyz, world_pos) + _410.fa_cl_fwd.w, _410.fa_cl_grid.w) / _410.fa_cl_grid.w) * _410.fa_cl_grid.z)), 0, int(_410.fa_cl_info.y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5) + 0.5) * _410.fa_cl_grid.y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5) + 0.5) * _410.fa_cl_grid.x)), 0, _487 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    float3 param = world_pos;\n    float4 _567 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _410);\n    return int2(int(_567.x), int(_567.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_410.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1965 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _410);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2054 = fa_linear_to_srgb(param);\n        c = _2054;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2062 = fa_srgb_to_linear(param_1);\n            c = _2062;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _182;\n    if (bool(i.front_facing))\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    float3 _206 = fast::normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    float3 _234 = fast::normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    float3 _237;\n    if (bool(i.front_facing))\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _410, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _410.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2093 = fa_tex_fix(param_2, param_3);\n    float4 _2941 = base_t;\n    _2941.x = _2093.x;\n    _2941.y = _2093.y;\n    _2941.z = _2093.z;\n    base_t = _2941;\n    float4 _2107 = (_2941 * _410.fa_base_color) * i.vertex_color;\n    float3 _2865 = i.world_normal;\n    if (_410.fa_maps.z > 0.5)\n    {\n        float param_4 = _410.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2139 = fa_tex_fix(param_6, param_7);\n        float3 _2142 = (_2139 * 2.0) - float3(1.0);\n        float2 _2147 = _2142.xy * _410.fa_maps.x;\n        float3 _2949 = _2142;\n        _2949.x = _2147.x;\n        _2949.y = _2147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2949;\n        _2865 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _410.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2176 = fa_tex_fix(param_12, param_13);\n    float4 _2952 = mrt;\n    _2952.x = _2176.x;\n    _2952.y = _2176.y;\n    _2952.z = _2176.z;\n    mrt = _2952;\n    float param_14 = _410.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2215 = fa_tex_fix(param_16, param_17);\n    float param_18 = _410.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2242 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2107.xyz, _2107.w, _2865, fast::clamp(_410.fa_pbr.x * _2176.z, 0.0, 1.0), fast::clamp(_410.fa_pbr.y * _2176.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_410.fa_maps.y * (_2215.x - 1.0)), _410.fa_emissive.xyz + (_410.fa_model_emissive.xyz * _2242) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _648 = rect.zw - rect.xy;\n    float2 _652 = _648 * atlas;\n    float2 _656 = ddx * _652;\n    float2 _660 = ddy * _652;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _648)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _695 = dfdx(world_pos);\n    float3 _698 = dfdy(world_pos);\n    bool _701 = _410.fa_counts.y < 0.5;\n    bool _708;\n    if (!_701)\n    {\n        _708 = _410.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _715 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _410);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(_410.fa_counts.y + 0.5);\n    int param_1 = _729;\n    float4 _733 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    float4 _745 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _746 = _745.x;\n    int _752 = int(_410.fa_counts.w + 0.5) - 1;\n    int _756 = int(_715.z);\n    float3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        float4 _792 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_792.w + 0.5) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        float4 _807 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _787 + 1;\n        float4 _812 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _787 + 2;\n        float4 _817 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        float3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        float3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = fast::clamp(dot(geo_normal, fast::normalize(_834)) * _792.z, 0.0, 1.0);\n        if (_875 <= 0.0)\n        {\n            continue;\n        }\n        float _895 = (fast::clamp((0.5 - abs(_839)) * 10.0, 0.0, 1.0) * _875) * _792.x;\n        float2 _903 = float2(_825 + 0.5, 0.5 - _832);\n        float2 _913 = float2(dot(_820, _695), dot(_827, _695));\n        float2 _923 = float2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        float4 _928 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _787 + 3;\n        float4 _933 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _787 + 4;\n        float4 _938 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            float4 param_11 = _933;\n            float2 param_12 = _903;\n            float2 param_13 = _736;\n            float2 param_14 = _913;\n            float2 param_15 = _923;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_746 > 0.5) && (_746 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _974 = fa_dc_to_linear(param_16);\n                float4 _2903 = tx;\n                _2903.x = _974.x;\n                _2903.y = _974.y;\n                _2903.z = _974.z;\n                tx = _2903;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_895 * tex_a) * _928.w, 0.0, 1.0)));\n        if (_938.z > _938.x)\n        {\n            float4 param_17 = _938;\n            float2 param_18 = _903;\n            float2 param_19 = _736;\n            float2 param_20 = _913;\n            float2 param_21 = _923;\n            float4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_746 > 1.5)\n            {\n                float3 param_22 = _1018.xyz;\n                float3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            float3 _1038 = (_1022 * 2.0) - float3(1.0);\n            float2 _1043 = _1038.xy * _792.y;\n            float3 _1065 = (fast::normalize(_820) * _1043.x) + (fast::normalize(_827) * _1043.y);\n            float3 _1068 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1068, fast::normalize((_1068 * fast::max(_1038.z, 0.0500000007450580596923828125)) + (_1065 - (_1068 * dot(_1068, _1065)))), float3(fast::clamp(_895 * (_948 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_410.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _410.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410)\n{\n    int param = (int(_410.fa_cl_info.x) + int(_410.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _410);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _282 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _288 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _291 = _288.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _298 = _291 < 0.5;\n    float3 l;\n    if (_298)\n    {\n        l = fast::normalize(_282.xyz);\n    }\n    else\n    {\n        float3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / float3(fast::max(_312, 9.9999997473787516355514526367188e-05));\n        float _327 = _312 / fast::max(_282.w, 0.001000000047497451305389404296875);\n        float _333 = fast::clamp(1.0 - (_327 * _327), 0.0, 1.0);\n        atten = _333 * _333;\n        if (_291 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _347 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            float4 _364 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5)\n            {\n                cos_inner = mix(_357, 1.0, 0.25);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, fast::normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _288.xyz * atten, atten, 1.0, dist, _396 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1150)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = _1150.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = _1150.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = _1150.fa_shadow_split.z;\n            }\n            else\n            {\n                _1164 = _1150.fa_shadow_split.w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex)\n{\n    float _1202 = fast::max(_1150.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1207 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1220 = fast::min(_1213 / fast::max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1225;\n    if (_1150.fa_shadow_bias.y > 0.0)\n    {\n        _1225 = _1150.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1225 = 1.5 * _1150.fa_shadow_info[ci].x;\n    }\n    float4 _1250 = _1150.fa_shadow_mat[ci] * float4(world + (n * (_1225 * _1213)), 1.0);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < _1150.fa_shadow_rect[ci].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > _1150.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < _1150.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > _1150.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0;\n    }\n    float _1303;\n    if (_1150.fa_shadow_bias.x > 0.0)\n    {\n        _1303 = _1150.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1303 = 1.5 * _1150.fa_shadow_info[ci].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0 + (0.5 * _1220))) / _1202);\n    float _1331 = ((_1150.fa_shadow_info[ci].x * fast::min(_1220, 3.0)) * 0.5) / _1202;\n    int _1340 = int(_1150.fa_shadow_cfg.z + 0.5);\n    if (_1340 == 1)\n    {\n        float2 param = _1250.xy;\n        float4 param_1 = _1150.fa_shadow_rect[ci];\n        float _1351 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = fast::clamp(((_1150.fa_shadow_cfg.w * _1202) * 0.25) / _1150.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            float2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            float2 param_5 = _1250.xy + (_1394 * _1150.fa_shadow_bias.zw);\n            float4 param_6 = _1150.fa_shadow_rect[ci];\n            float _1405 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1322 - (sum / cnt), 0.0) * _1202) * _1150.fa_shadow_cfg.w) / _1150.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        float2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1250.xy + (_1468 * _1150.fa_shadow_bias.zw);\n        float4 param_11 = _1150.fa_shadow_rect[ci];\n        float _1479 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex)\n{\n    if (_410.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1509 = int(_1150.fa_shadow_cfg.x + 0.5);\n    if (_1509 < 1)\n    {\n        return 1.0;\n    }\n    float _1524 = dot(world - _1150.fa_shadow_eye.xyz, _1150.fa_shadow_fwd.xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param, _1150))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > _1150.fa_shadow_split.x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > _1150.fa_shadow_split.y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > _1150.fa_shadow_split.z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1150, fa_shadow_tex);\n        s = _1591;\n        if (_1591 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1150.fa_shadow_cfg.y > 0.0)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5, _1150);\n        }\n        else\n        {\n            _1616 = _1150.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1635 = _1150.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1150) - _1616, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1646 = fast::clamp((_1524 - (fa_shadow_split_at(param_7, _1150) - _1635)) / _1635, 0.0, 1.0);\n        if (_1646 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1150, fa_shadow_tex);\n                s2 = _1667;\n                if (_1667 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _410, thread float4& gl_FragCoord, constant fa_shadows& _1150, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2850 = _1993.direction;\n    float3 _2845 = _1993.color;\n    float _2847 = _1993.shadow;\n    int _2855 = _1993.type;\n    if ((_2855 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2850;\n        float _2007 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex, fa_world_pos);\n        _2847 = _2007;\n        _2845 *= _2007;\n    }\n    return LightSample{ _2850, _2845, _1993.attenuation, _2847, _1993._distance, _2855 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1897 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1900 = _1897.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1900 * _1900, exp2((-9.27999973297119140625) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_410.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _410.fa_env_horizon.w)).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625 * _1803;\n    return mix(mix(_410.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_410.fa_env_horizon.xyz, _410.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1803)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1833, 0.0500000007450580596923828125 + _1833, d.y))), ((_410.fa_env_sky.xyz + _410.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1803 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _410, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1939 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _410, fa_env_smp, fa_env_tex) * ((f0 * _1939.x) + float3(_1939.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1150)\n{\n    if (_1150.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1691 = int(_1150.fa_shadow_cfg.x + 0.5);\n    float _1701 = dot(world - _1150.fa_shadow_eye.xyz, _1150.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param, _1150);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > _1150.fa_shadow_split.x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > _1150.fa_shadow_split.y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > _1150.fa_shadow_split.z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _410 [[buffer(1)]], constant fa_shadows& _1150 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2770 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2770 = -_2770;\n    }\n    float3 _2285 = fast::normalize(_410.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _410, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2770, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2285, short(gl_FrontFacing) };\n    Surface _2293 = fa_standard_surface(param_1, _410, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2793 = _2293.albedo;\n    float _2794 = _2293.alpha;\n    float3 _2795 = _2293.normal;\n    float _2796 = _2293.metallic;\n    float _2797 = _2293.roughness;\n    float _2798 = _2293.occlusion;\n    float3 _2799 = _2293.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2770, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2285, short(gl_FrontFacing) };\n    Surface param_3 = _2293;\n    surface(param_2, param_3);\n    _2793 = param_3.albedo;\n    _2794 = param_3.alpha;\n    _2795 = param_3.normal;\n    _2796 = param_3.metallic;\n    _2797 = param_3.roughness;\n    _2798 = param_3.occlusion;\n    _2799 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2770;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _410, fa_decal_tex, fa_env_smp);\n    _2793 = param_6;\n    _2795 = param_7;\n    float3 result;\n    if (_410.fa_emissive.w > 0.5)\n    {\n        result = _2793;\n    }\n    else\n    {\n        float3 _2332 = fast::normalize(_2795);\n        float _2339 = fast::clamp(_2796, 0.0, 1.0);\n        float _2343 = fast::clamp(_2797, 0.0500000007450580596923828125, 1.0);\n        float _2347 = _2343 * _2343;\n        float _2351 = _2347 * _2347;\n        float _2356 = fast::max(dot(_2332, _2285), 9.9999997473787516355514526367188e-05);\n        float3 _2362 = _2793 * (1.0 - _2339);\n        float3 _2370 = mix(float3(0.039999999105930328369140625), _2793, float3(_2339));\n        float3 param_8 = _2332;\n        float3 lit = (fa_ambient_light(param_8, _410, fa_env_smp, fa_irr_tex) * _2362) * _2798;\n        int _2383 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2383; ln++)\n        {\n            int param_9 = ln;\n            int _2396 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _410, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _2396;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2770;\n            LightSample _2405 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _410, gl_FragCoord, _1150, fa_shadow_tex, in.fa_world_pos);\n            float3 _2828 = _2405.direction;\n            float _2413 = fast::max(dot(_2332, _2828), 0.0);\n            float3 _2424 = fast::normalize(_2828 + _2285);\n            float _2429 = fast::max(dot(_2332, _2424), 0.0);\n            float _2442 = ((_2429 * _2429) * (_2351 - 1.0)) + 1.0;\n            int param_13 = _2396;\n            lit += (((_2362 + (((_2370 + ((float3(1.0) - _2370) * powr(1.0 - fast::max(dot(_2285, _2424), 0.0), 5.0))) * (((_2351 / ((3.1415927410125732421875 * _2442) * _2442)) * (0.5 / fast::max(mix((2.0 * _2413) * _2356, _2413 + _2356, _2347), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2413))) * fa_light_rgb(param_13, fa_light_tex, fa_shadow_smp)) * (_2413 * (_2405.attenuation * _2405.shadow)));\n        }\n        float3 param_14 = _2332;\n        float3 param_15 = _2285;\n        float3 param_16 = _2370;\n        float param_17 = _2343;\n        float3 _2511 = lit;\n        float3 _2512 = _2511 + (fa_sky_reflection(param_14, param_15, param_16, param_17, _410, fa_env_smp, fa_env_tex) * _2798);\n        lit = _2512;\n        result = _2512;\n    }\n    float3 _2516 = result;\n    float3 _2517 = _2516 + _2799;\n    result = _2517;\n    float3 param_18 = _2517;\n    float3 param_19 = in.fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19, _1150);\n    bool _2526 = _410.fa_fog.w > 0.0;\n    bool _2534;\n    if (!_2526)\n    {\n        _2534 = _410.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2534 = _2526;\n    }\n    if (_2534)\n    {\n        float3 _2543 = in.fa_world_pos - _410.fa_camera_pos.xyz;\n        float _2550 = dot(_2543, _410.fa_fog_c.xyz);\n        bool _2554 = _410.fa_fog_c.w > 0.5;\n        float _2555;\n        if (_2554)\n        {\n            _2555 = _2550;\n        }\n        else\n        {\n            _2555 = length(_2543);\n        }\n        float _2567 = _2555 - _410.fa_fog_b.x;\n        if (_2567 > 0.0)\n        {\n            float _2576 = _410.fa_fog.w * _2567;\n            float tau = _2576 * _2576;\n            if (_410.fa_fog_b.y > 0.0)\n            {\n                float _2592;\n                if (_2554)\n                {\n                    _2592 = in.fa_world_pos.y - (_410.fa_fog_c.y * _2550);\n                }\n                else\n                {\n                    _2592 = _410.fa_camera_pos.y;\n                }\n                float _2613 = mix(_2592, in.fa_world_pos.y, fast::clamp(_410.fa_fog_b.x / _2555, 0.0, 1.0));\n                float _2617 = in.fa_world_pos.y - _2613;\n                float _2622 = _2613 - _410.fa_fog_b.z;\n                float _2627 = in.fa_world_pos.y - _410.fa_fog_b.z;\n                bool _2630 = _2622 <= 0.0;\n                bool _2631 = !_2630;\n                bool _2637;\n                if (_2631)\n                {\n                    _2637 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2637 = _2630;\n                }\n                float _2638;\n                if (_2637)\n                {\n                    _2638 = _410.fa_fog_b.y;\n                }\n                else\n                {\n                    _2638 = _410.fa_fog_b.y * exp(-fast::min(_410.fa_fog_b.w * _2622, 80.0));\n                }\n                bool _2665;\n                if (_2631)\n                {\n                    _2665 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2665 = _2630;\n                }\n                float _2666;\n                if (_2665)\n                {\n                    _2666 = _410.fa_fog_b.y * _2622;\n                }\n                else\n                {\n                    _2666 = (_410.fa_fog_b.y * (1.0 - exp(-fast::min(_410.fa_fog_b.w * _2622, 80.0)))) / _410.fa_fog_b.w;\n                }\n                bool _2691 = _2627 <= 0.0;\n                bool _2698;\n                if (!_2691)\n                {\n                    _2698 = _410.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2698 = _2691;\n                }\n                float _2699;\n                if (_2698)\n                {\n                    _2699 = _410.fa_fog_b.y * _2627;\n                }\n                else\n                {\n                    _2699 = (_410.fa_fog_b.y * (1.0 - exp(-fast::min(_410.fa_fog_b.w * _2627, 80.0)))) / _410.fa_fog_b.w;\n                }\n                float _2726;\n                if (abs(_2617) < 0.001000000047497451305389404296875)\n                {\n                    _2726 = _2638;\n                }\n                else\n                {\n                    _2726 = (_2699 - _2666) / _2617;\n                }\n                tau += (_2567 * fast::max(_2726, 0.0));\n            }\n            result = mix(result, _410.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2794);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _145)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _45)\n{\n    v.world_pos += float3(_45.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _45, constant fa_mesh_vs_params& _145, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _145);\n    vertex0(param_6, _45);\n    float4 _189 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_145.fa_light_vp * _189).z;\n    fa_pre_r0 = float3(_145.fa_light_vp[0].x, _145.fa_light_vp[1].x, _145.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_145.fa_light_vp[0].y, _145.fa_light_vp[1].y, _145.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_145.fa_light_vp[0].z, _145.fa_light_vp[1].z, _145.fa_light_vp[2].z);\n    gl_Position = _145.fa_view_proj * _189;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _145 [[buffer(0)]], constant fa_material_vs& _45 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _45, _145, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    float4 _241 = (_591 * _213.fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _572, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _519 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _519, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _519, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _197)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_197.fa_joint_rows[_188] * weights[i]);\n        r1 += (_197.fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197.fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _150)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _50)\n{\n    v.world_pos += float3(_50.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _50, constant fa_mesh_vs_params& _150, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _150);\n    vertex0(param_6, _50);\n    float4 _302 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_150.fa_light_vp * _302).z;\n    fa_pre_r0 = float3(_150.fa_light_vp[0].x, _150.fa_light_vp[1].x, _150.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_150.fa_light_vp[0].y, _150.fa_light_vp[1].y, _150.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_150.fa_light_vp[0].z, _150.fa_light_vp[1].z, _150.fa_light_vp[2].z);\n    gl_Position = _150.fa_view_proj * _302;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _150 [[buffer(0)]], constant fa_skin& _197 [[buffer(3)]], constant fa_material_vs& _50 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _197);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _50, _150, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    float4 _241 = (_591 * _213.fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _572, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _519 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _519, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _519, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
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
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _36)\n{\n    v.world_pos += float3(_36.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_material_vs& _36 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    vertex0(param_6, _36);\n    out.gl_Position = _136.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _188)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_188.fa_joint_rows[_179] * weights[i]);\n        r1 += (_188.fa_joint_rows[_179 + 1] * weights[i]);\n        r2 += (_188.fa_joint_rows[_179 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _141)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _41)\n{\n    v.world_pos += float3(_41.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _141 [[buffer(0)]], constant fa_skin& _188 [[buffer(3)]], constant fa_material_vs& _41 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _188);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _141);\n    vertex0(param_8, _41);\n    out.gl_Position = _141.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_188",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
