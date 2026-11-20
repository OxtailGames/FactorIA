{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    bool _420 = _415.fa_cl_info.x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return float4(0.0);\n    }\n    float4 _459 = float4(world_pos, 1.0);\n    float _466 = dot(_415.fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _488 = float2(dot(_415.fa_cl_vpx, _459), dot(_415.fa_cl_vpy, _459)) / float2(_466);\n    int _492 = int(_415.fa_cl_grid.x);\n    int _496 = int(_415.fa_cl_grid.y);\n    int param = (int(_415.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_415.fa_cl_fwd.xyz, world_pos) + _415.fa_cl_fwd.w, _415.fa_cl_grid.w) / _415.fa_cl_grid.w) * _415.fa_cl_grid.z)), 0, int(_415.fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * _415.fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * _415.fa_cl_grid.x)), 0, _492 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    float3 param = world_pos;\n    float4 _572 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _415);\n    return int2(int(_572.x), int(_572.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_415.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2003 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _415);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _196;\n    if (bool(i.front_facing))\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    float3 _220 = fast::normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    float3 _248 = fast::normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    float3 _251;\n    if (bool(i.front_facing))\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _415, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _415.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2140 = fa_tex_fix(param_2, param_3);\n    float4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    float4 _2154 = (_2900 * _415.fa_base_color) * i.vertex_color;\n    float3 _2824 = i.world_normal;\n    if (_415.fa_maps.z > 0.5)\n    {\n        float param_4 = _415.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2186 = fa_tex_fix(param_6, param_7);\n        float3 _2189 = (_2186 * 2.0) - float3(1.0);\n        float2 _2194 = _2189.xy * _415.fa_maps.x;\n        float3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _415.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2223 = fa_tex_fix(param_12, param_13);\n    float4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = _415.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2289 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2154.xyz, _2154.w, _2824, fast::clamp(_415.fa_pbr.x * _2223.z, 0.0, 1.0), fast::clamp(_415.fa_pbr.y * _2223.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_415.fa_maps.y * (_2262.x - 1.0)), _415.fa_emissive.xyz + (_415.fa_model_emissive.xyz * _2289) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _653 = rect.zw - rect.xy;\n    float2 _657 = _653 * atlas;\n    float2 _661 = ddx * _657;\n    float2 _665 = ddy * _657;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _653)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _700 = dfdx(world_pos);\n    float3 _703 = dfdy(world_pos);\n    bool _706 = _415.fa_counts.y < 0.5;\n    bool _713;\n    if (!_706)\n    {\n        _713 = _415.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _720 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _415);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(_415.fa_counts.y + 0.5);\n    int param_1 = _734;\n    float4 _738 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    float4 _750 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _751 = _750.x;\n    int _757 = int(_415.fa_counts.w + 0.5) - 1;\n    int _761 = int(_720.z);\n    float3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        float4 _797 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_797.w + 0.5) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        float4 _812 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _792 + 1;\n        float4 _817 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _792 + 2;\n        float4 _822 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        float3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        float3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = fast::clamp(dot(geo_normal, fast::normalize(_839)) * _797.z, 0.0, 1.0);\n        if (_880 <= 0.0)\n        {\n            continue;\n        }\n        float _900 = (fast::clamp((0.5 - abs(_844)) * 10.0, 0.0, 1.0) * _880) * _797.x;\n        float2 _908 = float2(_830 + 0.5, 0.5 - _837);\n        float2 _918 = float2(dot(_825, _700), dot(_832, _700));\n        float2 _928 = float2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        float4 _933 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _792 + 3;\n        float4 _938 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _792 + 4;\n        float4 _943 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            float4 param_11 = _938;\n            float2 param_12 = _908;\n            float2 param_13 = _741;\n            float2 param_14 = _918;\n            float2 param_15 = _928;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_751 > 0.5) && (_751 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _979 = fa_dc_to_linear(param_16);\n                float4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_900 * tex_a) * _933.w, 0.0, 1.0)));\n        if (_943.z > _943.x)\n        {\n            float4 param_17 = _943;\n            float2 param_18 = _908;\n            float2 param_19 = _741;\n            float2 param_20 = _918;\n            float2 param_21 = _928;\n            float4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_751 > 1.5)\n            {\n                float3 param_22 = _1023.xyz;\n                float3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            float3 _1043 = (_1027 * 2.0) - float3(1.0);\n            float2 _1048 = _1043.xy * _797.y;\n            float3 _1070 = (fast::normalize(_825) * _1048.x) + (fast::normalize(_832) * _1048.y);\n            float3 _1073 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1073, fast::normalize((_1073 * fast::max(_1043.z, 0.0500000007450580596923828125)) + (_1070 - (_1073 * dot(_1073, _1070)))), float3(fast::clamp(_900 * (_953 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _415.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1902 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1905 = _1902.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1905 * _1905, exp2((-9.27999973297119140625) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _415.fa_env_horizon.w)).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625 * _1808;\n    return mix(mix(_415.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_415.fa_env_horizon.xyz, _415.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1808)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1838, 0.0500000007450580596923828125 + _1838, d.y))), ((_415.fa_env_sky.xyz + _415.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1808 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1944 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _415, fa_env_smp, fa_env_tex) * ((f0 * _1944.x) + float3(_1944.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _415, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _415, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    int param = (int(_415.fa_cl_info.x) + int(_415.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _415);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    float3 l;\n    if (_304)\n    {\n        l = fast::normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / float3(fast::max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / fast::max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = fast::clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, fast::normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _294.xyz * atten, atten, 1.0, dist, _401 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1155)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = _1155.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = _1155.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = _1155.fa_shadow_split.z;\n            }\n            else\n            {\n                _1169 = _1155.fa_shadow_split.w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex)\n{\n    float _1207 = fast::max(_1155.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1212 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1218 = sqrt(1.0 - (_1212 * _1212));\n    float _1225 = fast::min(_1218 / fast::max(_1212, 0.20000000298023223876953125), 4.0);\n    float _1230;\n    if (_1155.fa_shadow_bias.y > 0.0)\n    {\n        _1230 = _1155.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1230 = 1.5 * _1155.fa_shadow_info[ci].x;\n    }\n    float4 _1255 = _1155.fa_shadow_mat[ci] * float4(world + (n * (_1230 * _1218)), 1.0);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < _1155.fa_shadow_rect[ci].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1155.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < _1155.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > _1155.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0;\n    }\n    float _1308;\n    if (_1155.fa_shadow_bias.x > 0.0)\n    {\n        _1308 = _1155.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1308 = 1.5 * _1155.fa_shadow_info[ci].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0 + (0.5 * _1225))) / _1207);\n    float _1336 = ((_1155.fa_shadow_info[ci].x * fast::min(_1225, 3.0)) * 0.5) / _1207;\n    int _1345 = int(_1155.fa_shadow_cfg.z + 0.5);\n    if (_1345 == 1)\n    {\n        float2 param = _1255.xy;\n        float4 param_1 = _1155.fa_shadow_rect[ci];\n        float _1356 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = fast::clamp(((_1155.fa_shadow_cfg.w * _1207) * 0.25) / _1155.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            float2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            float2 param_5 = _1255.xy + (_1399 * _1155.fa_shadow_bias.zw);\n            float4 param_6 = _1155.fa_shadow_rect[ci];\n            float _1410 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1327 - (sum / cnt), 0.0) * _1207) * _1155.fa_shadow_cfg.w) / _1155.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        float2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1255.xy + (_1473 * _1155.fa_shadow_bias.zw);\n        float4 param_11 = _1155.fa_shadow_rect[ci];\n        float _1484 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex)\n{\n    if (_415.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1514 = int(_1155.fa_shadow_cfg.x + 0.5);\n    if (_1514 < 1)\n    {\n        return 1.0;\n    }\n    float _1529 = dot(world - _1155.fa_shadow_eye.xyz, _1155.fa_shadow_fwd.xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param, _1155))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > _1155.fa_shadow_split.x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > _1155.fa_shadow_split.y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > _1155.fa_shadow_split.z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1155, fa_shadow_tex);\n        s = _1596;\n        if (_1596 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1155.fa_shadow_cfg.y > 0.0)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5, _1155);\n        }\n        else\n        {\n            _1621 = _1155.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1640 = _1155.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1155) - _1621, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1651 = fast::clamp((_1529 - (fa_shadow_split_at(param_7, _1155) - _1640)) / _1640, 0.0, 1.0);\n        if (_1651 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1155, fa_shadow_tex);\n                s2 = _1672;\n                if (_1672 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2809 = _2031.direction;\n    float3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex, fa_world_pos);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    return LightSample{ _2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1155)\n{\n    if (_1155.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1696 = int(_1155.fa_shadow_cfg.x + 0.5);\n    float _1706 = dot(world - _1155.fa_shadow_eye.xyz, _1155.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param, _1155);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > _1155.fa_shadow_split.x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > _1155.fa_shadow_split.y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > _1155.fa_shadow_split.z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _415 [[buffer(1)]], constant fa_shadows& _1155 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2687 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    float3 _2332 = fast::normalize(_415.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n    Surface _2340 = fa_standard_surface(param_1, _415, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    float3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    float3 _2732 = _2340.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2687;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _415, fa_decal_tex, fa_env_smp);\n    _2726 = param_6;\n    _2728 = param_7;\n    float3 result;\n    if (_415.fa_emissive.w > 0.5)\n    {\n        result = _2726;\n    }\n    else\n    {\n        float3 _2378 = _2728;\n        float3 _2379 = fast::normalize(_2378);\n        _2728 = _2379;\n        float3 param_8 = _2379;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n        float3 param_11 = fa_ambient_light(param_8, _415, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_9, param_10, param_11, _415, fa_env_smp, fa_env_tex);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot);\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _2687;\n            SurfaceInput param_16 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n            Surface param_17 = Surface{ _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2435 = result;\n    float3 _2436 = _2435 + _2732;\n    result = _2436;\n    float3 param_19 = _2436;\n    float3 param_20 = in.fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20, _1155);\n    bool _2445 = _415.fa_fog.w > 0.0;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = _415.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        float3 _2462 = in.fa_world_pos - _415.fa_camera_pos.xyz;\n        float _2469 = dot(_2462, _415.fa_fog_c.xyz);\n        bool _2473 = _415.fa_fog_c.w > 0.5;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - _415.fa_fog_b.x;\n        if (_2486 > 0.0)\n        {\n            float _2495 = _415.fa_fog.w * _2486;\n            float tau = _2495 * _2495;\n            if (_415.fa_fog_b.y > 0.0)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = in.fa_world_pos.y - (_415.fa_fog_c.y * _2469);\n                }\n                else\n                {\n                    _2511 = _415.fa_camera_pos.y;\n                }\n                float _2532 = mix(_2511, in.fa_world_pos.y, fast::clamp(_415.fa_fog_b.x / _2474, 0.0, 1.0));\n                float _2536 = in.fa_world_pos.y - _2532;\n                float _2541 = _2532 - _415.fa_fog_b.z;\n                float _2546 = in.fa_world_pos.y - _415.fa_fog_b.z;\n                bool _2549 = _2541 <= 0.0;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = _415.fa_fog_b.y;\n                }\n                else\n                {\n                    _2557 = _415.fa_fog_b.y * exp(-fast::min(_415.fa_fog_b.w * _2541, 80.0));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = _415.fa_fog_b.y * _2541;\n                }\n                else\n                {\n                    _2585 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2541, 80.0)))) / _415.fa_fog_b.w;\n                }\n                bool _2610 = _2546 <= 0.0;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = _415.fa_fog_b.y * _2546;\n                }\n                else\n                {\n                    _2618 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2546, 80.0)))) / _415.fa_fog_b.w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * fast::max(_2645, 0.0));\n            }\n            result = mix(result, _415.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2727);\n    return out;\n}\n\n",
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
            "inst_name": "_415",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1155",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    bool _420 = _415.fa_cl_info.x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return float4(0.0);\n    }\n    float4 _459 = float4(world_pos, 1.0);\n    float _466 = dot(_415.fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _488 = float2(dot(_415.fa_cl_vpx, _459), dot(_415.fa_cl_vpy, _459)) / float2(_466);\n    int _492 = int(_415.fa_cl_grid.x);\n    int _496 = int(_415.fa_cl_grid.y);\n    int param = (int(_415.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_415.fa_cl_fwd.xyz, world_pos) + _415.fa_cl_fwd.w, _415.fa_cl_grid.w) / _415.fa_cl_grid.w) * _415.fa_cl_grid.z)), 0, int(_415.fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * _415.fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * _415.fa_cl_grid.x)), 0, _492 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    float3 param = world_pos;\n    float4 _572 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _415);\n    return int2(int(_572.x), int(_572.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_415.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2003 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _415);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _196;\n    if (bool(i.front_facing))\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    float3 _220 = fast::normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    float3 _248 = fast::normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    float3 _251;\n    if (bool(i.front_facing))\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _415, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _415.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2140 = fa_tex_fix(param_2, param_3);\n    float4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    float4 _2154 = (_2900 * _415.fa_base_color) * i.vertex_color;\n    float3 _2824 = i.world_normal;\n    if (_415.fa_maps.z > 0.5)\n    {\n        float param_4 = _415.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2186 = fa_tex_fix(param_6, param_7);\n        float3 _2189 = (_2186 * 2.0) - float3(1.0);\n        float2 _2194 = _2189.xy * _415.fa_maps.x;\n        float3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _415.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2223 = fa_tex_fix(param_12, param_13);\n    float4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = _415.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2289 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2154.xyz, _2154.w, _2824, fast::clamp(_415.fa_pbr.x * _2223.z, 0.0, 1.0), fast::clamp(_415.fa_pbr.y * _2223.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_415.fa_maps.y * (_2262.x - 1.0)), _415.fa_emissive.xyz + (_415.fa_model_emissive.xyz * _2289) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _653 = rect.zw - rect.xy;\n    float2 _657 = _653 * atlas;\n    float2 _661 = ddx * _657;\n    float2 _665 = ddy * _657;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _653)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _700 = dfdx(world_pos);\n    float3 _703 = dfdy(world_pos);\n    bool _706 = _415.fa_counts.y < 0.5;\n    bool _713;\n    if (!_706)\n    {\n        _713 = _415.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _720 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _415);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(_415.fa_counts.y + 0.5);\n    int param_1 = _734;\n    float4 _738 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    float4 _750 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _751 = _750.x;\n    int _757 = int(_415.fa_counts.w + 0.5) - 1;\n    int _761 = int(_720.z);\n    float3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        float4 _797 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_797.w + 0.5) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        float4 _812 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _792 + 1;\n        float4 _817 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _792 + 2;\n        float4 _822 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        float3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        float3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = fast::clamp(dot(geo_normal, fast::normalize(_839)) * _797.z, 0.0, 1.0);\n        if (_880 <= 0.0)\n        {\n            continue;\n        }\n        float _900 = (fast::clamp((0.5 - abs(_844)) * 10.0, 0.0, 1.0) * _880) * _797.x;\n        float2 _908 = float2(_830 + 0.5, 0.5 - _837);\n        float2 _918 = float2(dot(_825, _700), dot(_832, _700));\n        float2 _928 = float2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        float4 _933 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _792 + 3;\n        float4 _938 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _792 + 4;\n        float4 _943 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            float4 param_11 = _938;\n            float2 param_12 = _908;\n            float2 param_13 = _741;\n            float2 param_14 = _918;\n            float2 param_15 = _928;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_751 > 0.5) && (_751 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _979 = fa_dc_to_linear(param_16);\n                float4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_900 * tex_a) * _933.w, 0.0, 1.0)));\n        if (_943.z > _943.x)\n        {\n            float4 param_17 = _943;\n            float2 param_18 = _908;\n            float2 param_19 = _741;\n            float2 param_20 = _918;\n            float2 param_21 = _928;\n            float4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_751 > 1.5)\n            {\n                float3 param_22 = _1023.xyz;\n                float3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            float3 _1043 = (_1027 * 2.0) - float3(1.0);\n            float2 _1048 = _1043.xy * _797.y;\n            float3 _1070 = (fast::normalize(_825) * _1048.x) + (fast::normalize(_832) * _1048.y);\n            float3 _1073 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1073, fast::normalize((_1073 * fast::max(_1043.z, 0.0500000007450580596923828125)) + (_1070 - (_1073 * dot(_1073, _1070)))), float3(fast::clamp(_900 * (_953 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _415.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1902 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1905 = _1902.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1905 * _1905, exp2((-9.27999973297119140625) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _415.fa_env_horizon.w)).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625 * _1808;\n    return mix(mix(_415.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_415.fa_env_horizon.xyz, _415.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1808)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1838, 0.0500000007450580596923828125 + _1838, d.y))), ((_415.fa_env_sky.xyz + _415.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1808 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1944 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _415, fa_env_smp, fa_env_tex) * ((f0 * _1944.x) + float3(_1944.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _415, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _415, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _415, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    int param = (int(_415.fa_cl_info.x) + int(_415.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _415);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    float3 l;\n    if (_304)\n    {\n        l = fast::normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / float3(fast::max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / fast::max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = fast::clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, fast::normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _294.xyz * atten, atten, 1.0, dist, _401 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1155)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = _1155.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = _1155.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = _1155.fa_shadow_split.z;\n            }\n            else\n            {\n                _1169 = _1155.fa_shadow_split.w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex)\n{\n    float _1207 = fast::max(_1155.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1212 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1218 = sqrt(1.0 - (_1212 * _1212));\n    float _1225 = fast::min(_1218 / fast::max(_1212, 0.20000000298023223876953125), 4.0);\n    float _1230;\n    if (_1155.fa_shadow_bias.y > 0.0)\n    {\n        _1230 = _1155.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1230 = 1.5 * _1155.fa_shadow_info[ci].x;\n    }\n    float4 _1255 = _1155.fa_shadow_mat[ci] * float4(world + (n * (_1230 * _1218)), 1.0);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < _1155.fa_shadow_rect[ci].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1155.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < _1155.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > _1155.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0;\n    }\n    float _1308;\n    if (_1155.fa_shadow_bias.x > 0.0)\n    {\n        _1308 = _1155.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1308 = 1.5 * _1155.fa_shadow_info[ci].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0 + (0.5 * _1225))) / _1207);\n    float _1336 = ((_1155.fa_shadow_info[ci].x * fast::min(_1225, 3.0)) * 0.5) / _1207;\n    int _1345 = int(_1155.fa_shadow_cfg.z + 0.5);\n    if (_1345 == 1)\n    {\n        float2 param = _1255.xy;\n        float4 param_1 = _1155.fa_shadow_rect[ci];\n        float _1356 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = fast::clamp(((_1155.fa_shadow_cfg.w * _1207) * 0.25) / _1155.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            float2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            float2 param_5 = _1255.xy + (_1399 * _1155.fa_shadow_bias.zw);\n            float4 param_6 = _1155.fa_shadow_rect[ci];\n            float _1410 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1327 - (sum / cnt), 0.0) * _1207) * _1155.fa_shadow_cfg.w) / _1155.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        float2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1255.xy + (_1473 * _1155.fa_shadow_bias.zw);\n        float4 param_11 = _1155.fa_shadow_rect[ci];\n        float _1484 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex)\n{\n    if (_415.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1514 = int(_1155.fa_shadow_cfg.x + 0.5);\n    if (_1514 < 1)\n    {\n        return 1.0;\n    }\n    float _1529 = dot(world - _1155.fa_shadow_eye.xyz, _1155.fa_shadow_fwd.xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param, _1155))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > _1155.fa_shadow_split.x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > _1155.fa_shadow_split.y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > _1155.fa_shadow_split.z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1155, fa_shadow_tex);\n        s = _1596;\n        if (_1596 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1155.fa_shadow_cfg.y > 0.0)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5, _1155);\n        }\n        else\n        {\n            _1621 = _1155.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1640 = _1155.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1155) - _1621, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1651 = fast::clamp((_1529 - (fa_shadow_split_at(param_7, _1155) - _1640)) / _1640, 0.0, 1.0);\n        if (_1651 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1155, fa_shadow_tex);\n                s2 = _1672;\n                if (_1672 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _1155, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2809 = _2031.direction;\n    float3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex, fa_world_pos);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    return LightSample{ _2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1155)\n{\n    if (_1155.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1696 = int(_1155.fa_shadow_cfg.x + 0.5);\n    float _1706 = dot(world - _1155.fa_shadow_eye.xyz, _1155.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param, _1155);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > _1155.fa_shadow_split.x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > _1155.fa_shadow_split.y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > _1155.fa_shadow_split.z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _415 [[buffer(1)]], constant fa_shadows& _1155 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2687 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    float3 _2332 = fast::normalize(_415.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n    Surface _2340 = fa_standard_surface(param_1, _415, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    float3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    float3 _2732 = _2340.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2687;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _415, fa_decal_tex, fa_env_smp);\n    _2726 = param_6;\n    _2728 = param_7;\n    float3 result;\n    if (_415.fa_emissive.w > 0.5)\n    {\n        result = _2726;\n    }\n    else\n    {\n        float3 _2378 = _2728;\n        float3 _2379 = fast::normalize(_2378);\n        _2728 = _2379;\n        float3 param_8 = _2379;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n        float3 param_11 = fa_ambient_light(param_8, _415, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_9, param_10, param_11, _415, fa_env_smp, fa_env_tex);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot);\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _2687;\n            SurfaceInput param_16 = SurfaceInput{ in.fa_world_pos, _2687, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2332, short(gl_FrontFacing) };\n            Surface param_17 = Surface{ _2726, _2727, _2728, _2729, _2730, _2731, _2732 };\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _1155, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2435 = result;\n    float3 _2436 = _2435 + _2732;\n    result = _2436;\n    float3 param_19 = _2436;\n    float3 param_20 = in.fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20, _1155);\n    bool _2445 = _415.fa_fog.w > 0.0;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = _415.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        float3 _2462 = in.fa_world_pos - _415.fa_camera_pos.xyz;\n        float _2469 = dot(_2462, _415.fa_fog_c.xyz);\n        bool _2473 = _415.fa_fog_c.w > 0.5;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - _415.fa_fog_b.x;\n        if (_2486 > 0.0)\n        {\n            float _2495 = _415.fa_fog.w * _2486;\n            float tau = _2495 * _2495;\n            if (_415.fa_fog_b.y > 0.0)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = in.fa_world_pos.y - (_415.fa_fog_c.y * _2469);\n                }\n                else\n                {\n                    _2511 = _415.fa_camera_pos.y;\n                }\n                float _2532 = mix(_2511, in.fa_world_pos.y, fast::clamp(_415.fa_fog_b.x / _2474, 0.0, 1.0));\n                float _2536 = in.fa_world_pos.y - _2532;\n                float _2541 = _2532 - _415.fa_fog_b.z;\n                float _2546 = in.fa_world_pos.y - _415.fa_fog_b.z;\n                bool _2549 = _2541 <= 0.0;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = _415.fa_fog_b.y;\n                }\n                else\n                {\n                    _2557 = _415.fa_fog_b.y * exp(-fast::min(_415.fa_fog_b.w * _2541, 80.0));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = _415.fa_fog_b.y * _2541;\n                }\n                else\n                {\n                    _2585 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2541, 80.0)))) / _415.fa_fog_b.w;\n                }\n                bool _2610 = _2546 <= 0.0;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = _415.fa_fog_b.y * _2546;\n                }\n                else\n                {\n                    _2618 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2546, 80.0)))) / _415.fa_fog_b.w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * fast::max(_2645, 0.0));\n            }\n            result = mix(result, _415.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2727);\n    return out;\n}\n\n",
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
            "inst_name": "_415",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1155",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213.fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _569, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _516 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213.fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _569, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _516 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
