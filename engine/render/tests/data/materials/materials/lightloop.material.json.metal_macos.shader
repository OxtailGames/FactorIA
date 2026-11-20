{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    bool _424 = _419.fa_cl_info.x < 0.0;\n    bool _431;\n    if (!_424)\n    {\n        _431 = _419.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _431 = _424;\n    }\n    bool _439;\n    if (!_431)\n    {\n        _439 = _419.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _439 = _431;\n    }\n    bool _446;\n    if (!_439)\n    {\n        _446 = _419.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _446 = _439;\n    }\n    bool _453;\n    if (!_446)\n    {\n        _453 = _419.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    if (_453)\n    {\n        return float4(0.0);\n    }\n    float4 _463 = float4(world_pos, 1.0);\n    float _470 = dot(_419.fa_cl_vpw, _463);\n    if (!(_470 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _492 = float2(dot(_419.fa_cl_vpx, _463), dot(_419.fa_cl_vpy, _463)) / float2(_470);\n    int _496 = int(_419.fa_cl_grid.x);\n    int _500 = int(_419.fa_cl_grid.y);\n    int param = (int(_419.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_419.fa_cl_fwd.xyz, world_pos) + _419.fa_cl_fwd.w, _419.fa_cl_grid.w) / _419.fa_cl_grid.w) * _419.fa_cl_grid.z)), 0, int(_419.fa_cl_info.y) - 1) * _500) + clamp(int(floor(((_492.y * 0.5) + 0.5) * _419.fa_cl_grid.y)), 0, _500 - 1)) * _496)) + clamp(int(floor(((_492.x * 0.5) + 0.5) * _419.fa_cl_grid.x)), 0, _496 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    float3 param = world_pos;\n    float4 _576 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _419);\n    return int2(int(_576.x), int(_576.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_419.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2000 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _419);\n    fa_cl_slot = _2000.x;\n    fa_cl_local = _2000.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2236 = fa_linear_to_srgb(param);\n        c = _2236;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2244 = fa_srgb_to_linear(param_1);\n            c = _2244;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _199;\n    if (bool(i.front_facing))\n    {\n        _199 = i.world_normal;\n    }\n    else\n    {\n        _199 = -i.world_normal;\n    }\n    float3 _223 = fast::normalize(i.world_tangent.xyz - (_199 * dot(_199, i.world_tangent.xyz)));\n    float3 _251 = fast::normalize(((_223 * m.x) + ((cross(_199, _223) * i.world_tangent.w) * m.y)) + (_199 * m.z));\n    float3 _254;\n    if (bool(i.front_facing))\n    {\n        _254 = _251;\n    }\n    else\n    {\n        _254 = -_251;\n    }\n    return _254;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _419, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _419.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2275 = fa_tex_fix(param_2, param_3);\n    float4 _2982 = base_t;\n    _2982.x = _2275.x;\n    _2982.y = _2275.y;\n    _2982.z = _2275.z;\n    base_t = _2982;\n    float4 _2289 = (_2982 * _419.fa_base_color) * i.vertex_color;\n    float3 _2906 = i.world_normal;\n    if (_419.fa_maps.z > 0.5)\n    {\n        float param_4 = _419.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2321 = fa_tex_fix(param_6, param_7);\n        float3 _2324 = (_2321 * 2.0) - float3(1.0);\n        float2 _2329 = _2324.xy * _419.fa_maps.x;\n        float3 _2990 = _2324;\n        _2990.x = _2329.x;\n        _2990.y = _2329.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2990;\n        _2906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _419.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2358 = fa_tex_fix(param_12, param_13);\n    float4 _2993 = mrt;\n    _2993.x = _2358.x;\n    _2993.y = _2358.y;\n    _2993.z = _2358.z;\n    mrt = _2993;\n    float param_14 = _419.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _419.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2424 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2289.xyz, _2289.w, _2906, fast::clamp(_419.fa_pbr.x * _2358.z, 0.0, 1.0), fast::clamp(_419.fa_pbr.y * _2358.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_419.fa_maps.y * (_2397.x - 1.0)), _419.fa_emissive.xyz + (_419.fa_model_emissive.xyz * _2424) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _657 = rect.zw - rect.xy;\n    float2 _661 = _657 * atlas;\n    float2 _665 = ddx * _661;\n    float2 _669 = ddy * _661;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _657)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_665, _665), dot(_669, _669)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _704 = dfdx(world_pos);\n    float3 _707 = dfdy(world_pos);\n    bool _710 = _419.fa_counts.y < 0.5;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _419.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    if (_717)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _724 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _419);\n    int _728 = int(_724.w);\n    if (_728 < 1)\n    {\n        return;\n    }\n    int _738 = int(_419.fa_counts.y + 0.5);\n    int param_1 = _738;\n    float4 _742 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _745 = _742.yz;\n    int _749 = int(_742.w);\n    int param_2 = _738 + 1;\n    float4 _754 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _755 = _754.x;\n    int _761 = int(_419.fa_counts.w + 0.5) - 1;\n    int _765 = int(_724.z);\n    float3 _1031;\n    for (int k = 0; k < _728; k++)\n    {\n        int _778 = _765 + k;\n        int param_3 = _749 + (_778 >> 2);\n        int _796 = (_738 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_778 & 3]) * 7);\n        int param_4 = _796 + 6;\n        float4 _801 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_801.w + 0.5) >> _761) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _796;\n        float4 _816 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _796 + 1;\n        float4 _821 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _796 + 2;\n        float4 _826 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _829 = _816.xyz;\n        float _834 = dot(_829, world_pos) + _816.w;\n        float3 _836 = _821.xyz;\n        float _841 = dot(_836, world_pos) + _821.w;\n        float3 _843 = _826.xyz;\n        float _848 = dot(_843, world_pos) + _826.w;\n        bool _853 = abs(_834) > 0.5;\n        bool _861;\n        if (!_853)\n        {\n            _861 = abs(_841) > 0.5;\n        }\n        else\n        {\n            _861 = _853;\n        }\n        bool _869;\n        if (!_861)\n        {\n            _869 = abs(_848) > 0.5;\n        }\n        else\n        {\n            _869 = _861;\n        }\n        if (_869)\n        {\n            continue;\n        }\n        float _884 = fast::clamp(dot(geo_normal, fast::normalize(_843)) * _801.z, 0.0, 1.0);\n        if (_884 <= 0.0)\n        {\n            continue;\n        }\n        float _904 = (fast::clamp((0.5 - abs(_848)) * 10.0, 0.0, 1.0) * _884) * _801.x;\n        float2 _912 = float2(_834 + 0.5, 0.5 - _841);\n        float2 _922 = float2(dot(_829, _704), dot(_836, _704));\n        float2 _932 = float2(dot(_829, _707), dot(_836, _707));\n        int param_8 = _796 + 5;\n        float4 _937 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _796 + 3;\n        float4 _942 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _796 + 4;\n        float4 _947 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _937.xyz;\n        bool _957 = _942.z > _942.x;\n        if (_957)\n        {\n            float4 param_11 = _942;\n            float2 param_12 = _912;\n            float2 param_13 = _745;\n            float2 param_14 = _922;\n            float2 param_15 = _932;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_755 > 0.5) && (_755 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _983 = fa_dc_to_linear(param_16);\n                float4 _2944 = tx;\n                _2944.x = _983.x;\n                _2944.y = _983.y;\n                _2944.z = _983.z;\n                tx = _2944;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_904 * tex_a) * _937.w, 0.0, 1.0)));\n        if (_947.z > _947.x)\n        {\n            float4 param_17 = _947;\n            float2 param_18 = _912;\n            float2 param_19 = _745;\n            float2 param_20 = _922;\n            float2 param_21 = _932;\n            float4 _1027 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_755 > 1.5)\n            {\n                float3 param_22 = _1027.xyz;\n                float3 _1037 = fa_dc_to_srgb(param_22);\n                _1031 = _1037;\n            }\n            else\n            {\n                _1031 = _1027.xyz;\n            }\n            float3 _1047 = (_1031 * 2.0) - float3(1.0);\n            float2 _1052 = _1047.xy * _801.y;\n            float3 _1074 = (fast::normalize(_829) * _1052.x) + (fast::normalize(_836) * _1052.y);\n            float3 _1077 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1077, fast::normalize((_1077 * fast::max(_1047.z, 0.0500000007450580596923828125)) + (_1074 - (_1077 * dot(_1077, _1074)))), float3(fast::clamp(_904 * (_957 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    int param = (int(_419.fa_cl_info.x) + int(_419.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _419);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _291 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _297 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _300 = _297.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _307 = _300 < 0.5;\n    float3 l;\n    if (_307)\n    {\n        l = fast::normalize(_291.xyz);\n    }\n    else\n    {\n        float3 _319 = _291.xyz - world_pos;\n        float _321 = length(_319);\n        dist = _321;\n        l = _319 / float3(fast::max(_321, 9.9999997473787516355514526367188e-05));\n        float _336 = _321 / fast::max(_291.w, 0.001000000047497451305389404296875);\n        float _342 = fast::clamp(1.0 - (_336 * _336), 0.0, 1.0);\n        atten = _342 * _342;\n        if (_300 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _356 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _366 = _356.w;\n            int param_3 = (li * 4) + 3;\n            float4 _373 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _374 = _373.x;\n            float cos_inner = _374;\n            if (_374 > 1.5)\n            {\n                cos_inner = mix(_366, 1.0, 0.25);\n            }\n            atten *= smoothstep(_366, cos_inner, dot(-l, fast::normalize(_356.xyz)));\n        }\n    }\n    int _405;\n    if (_307)\n    {\n        _405 = 0;\n    }\n    else\n    {\n        _405 = (_300 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _297.xyz * atten, atten, 1.0, dist, _405 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2085 = n < 0;\n    bool _2092;\n    if (!_2085)\n    {\n        _2092 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2092 = _2085;\n    }\n    if (_2092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1159)\n{\n    float _1149;\n    if (i == 0)\n    {\n        _1149 = _1159.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1165;\n        if (i == 1)\n        {\n            _1165 = _1159.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1173;\n            if (i == 2)\n            {\n                _1173 = _1159.fa_shadow_split.z;\n            }\n            else\n            {\n                _1173 = _1159.fa_shadow_split.w;\n            }\n            _1165 = _1173;\n        }\n        _1149 = _1165;\n    }\n    return _1149;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1137 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1137), sin(_1137)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex)\n{\n    float _1211 = fast::max(_1159.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1216 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1222 = sqrt(1.0 - (_1216 * _1216));\n    float _1229 = fast::min(_1222 / fast::max(_1216, 0.20000000298023223876953125), 4.0);\n    float _1234;\n    if (_1159.fa_shadow_bias.y > 0.0)\n    {\n        _1234 = _1159.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1234 = 1.5 * _1159.fa_shadow_info[ci].x;\n    }\n    float4 _1259 = _1159.fa_shadow_mat[ci] * float4(world + (n * (_1234 * _1222)), 1.0);\n    float _1266 = _1259.x;\n    bool _1269 = _1266 < _1159.fa_shadow_rect[ci].x;\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1266 > _1159.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1259.y < _1159.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1296;\n    if (!_1287)\n    {\n        _1296 = _1259.y > _1159.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1296 = _1287;\n    }\n    bool _1303;\n    if (!_1296)\n    {\n        _1303 = _1259.z > 1.0;\n    }\n    else\n    {\n        _1303 = _1296;\n    }\n    if (_1303)\n    {\n        return -1.0;\n    }\n    float _1312;\n    if (_1159.fa_shadow_bias.x > 0.0)\n    {\n        _1312 = _1159.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1312 = 1.5 * _1159.fa_shadow_info[ci].x;\n    }\n    float _1331 = _1259.z - ((_1312 * (1.0 + (0.5 * _1229))) / _1211);\n    float _1340 = ((_1159.fa_shadow_info[ci].x * fast::min(_1229, 3.0)) * 0.5) / _1211;\n    int _1349 = int(_1159.fa_shadow_cfg.z + 0.5);\n    if (_1349 == 1)\n    {\n        float2 param = _1259.xy;\n        float4 param_1 = _1159.fa_shadow_rect[ci];\n        float _1360 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1331 <= _1360);\n    }\n    float _1367 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1370 = _1349 == 2;\n    if (_1370)\n    {\n        float _1384 = fast::clamp(((_1159.fa_shadow_cfg.w * _1211) * 0.25) / _1159.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1367;\n            float2 _1403 = fa_shadow_vogel(param_2, param_3, param_4) * _1384;\n            float2 param_5 = _1259.xy + (_1403 * _1159.fa_shadow_bias.zw);\n            float4 param_6 = _1159.fa_shadow_rect[ci];\n            float _1414 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1414 < (_1331 - (length(_1403) * _1340)))\n            {\n                sum += _1414;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1331 - (sum / cnt), 0.0) * _1211) * _1159.fa_shadow_cfg.w) / _1159.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1458 = _1370 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1458; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1458;\n        float param_9 = _1367;\n        float2 _1477 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1259.xy + (_1477 * _1159.fa_shadow_bias.zw);\n        float4 param_11 = _1159.fa_shadow_rect[ci];\n        float _1488 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1331 - (length(_1477) * _1340)) <= _1488);\n    }\n    return lit / float(_1458);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex)\n{\n    if (_419.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1518 = int(_1159.fa_shadow_cfg.x + 0.5);\n    if (_1518 < 1)\n    {\n        return 1.0;\n    }\n    float _1533 = dot(world - _1159.fa_shadow_eye.xyz, _1159.fa_shadow_fwd.xyz);\n    int param = _1518 - 1;\n    if (_1533 > fa_shadow_split_at(param, _1159))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1545 = _1518 > 1;\n    bool _1552;\n    if (_1545)\n    {\n        _1552 = _1533 > _1159.fa_shadow_split.x;\n    }\n    else\n    {\n        _1552 = _1545;\n    }\n    if (_1552)\n    {\n        ci = 1;\n    }\n    bool _1556 = _1518 > 2;\n    bool _1563;\n    if (_1556)\n    {\n        _1563 = _1533 > _1159.fa_shadow_split.y;\n    }\n    else\n    {\n        _1563 = _1556;\n    }\n    if (_1563)\n    {\n        ci = 2;\n    }\n    bool _1567 = _1518 > 3;\n    bool _1574;\n    if (_1567)\n    {\n        _1574 = _1533 > _1159.fa_shadow_split.z;\n    }\n    else\n    {\n        _1574 = _1567;\n    }\n    if (_1574)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1518)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1600 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1159, fa_shadow_tex);\n        s = _1600;\n        if (_1600 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1159.fa_shadow_cfg.y > 0.0)\n    {\n        float _1625;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1625 = fa_shadow_split_at(param_5, _1159);\n        }\n        else\n        {\n            _1625 = _1159.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1644 = _1159.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1159) - _1625, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1655 = fast::clamp((_1533 - (fa_shadow_split_at(param_7, _1159) - _1644)) / _1644, 0.0, 1.0);\n        if (_1655 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1518)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1676 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1159, fa_shadow_tex);\n                s2 = _1676;\n                if (_1676 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1655);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2028 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2882 = _2028.direction;\n    float3 _2877 = _2028.color;\n    float _2879 = _2028.shadow;\n    int _2887 = _2028.type;\n    if ((_2887 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2882;\n        float _2042 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos);\n        _2879 = _2042;\n        _2877 *= _2042;\n    }\n    return LightSample{ _2882, _2877, _2028.attenuation, _2879, _2028._distance, _2887 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2059 = n < 0;\n    bool _2066;\n    if (!_2059)\n    {\n        _2066 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2066 = _2059;\n    }\n    if (_2066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1888 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1891 = _1888.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1891 * _1891, exp2((-9.27999973297119140625) * ndv)) * _1891) + _1888.y)) + _1888.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_419.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _419.fa_env_horizon.w)).xyz;\n    }\n    float _1812 = rough * rough;\n    float _1842 = 0.60000002384185791015625 * _1812;\n    return mix(mix(_419.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_419.fa_env_horizon.xyz, _419.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1812)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1842, 0.0500000007450580596923828125 + _1842, d.y))), ((_419.fa_env_sky.xyz + _419.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1812 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _419, fa_env_smp, fa_env_tex) * ((f0 * _1930.x) + float3(_1930.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _419, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2175)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2132 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2132 > bestPower)\n        {\n            bestPower = _2132;\n            best = n;\n        }\n    }\n    float3 lit = (_419.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2161 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2169;\n        if (dot(s.normal, _2161.direction) > 0.5)\n        {\n            _2169 = 1.0;\n        }\n        else\n        {\n            _2169 = _2175.dark;\n        }\n        lit += ((s.albedo * _2161.color) * _2169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _419, fa_env_smp, fa_env_tex) * _2175.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1159)\n{\n    if (_1159.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1700 = int(_1159.fa_shadow_cfg.x + 0.5);\n    float _1710 = dot(world - _1159.fa_shadow_eye.xyz, _1159.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1715 = _1700 > 0;\n    bool _1724;\n    if (_1715)\n    {\n        int param = _1700 - 1;\n        _1724 = _1710 <= fa_shadow_split_at(param, _1159);\n    }\n    else\n    {\n        _1724 = _1715;\n    }\n    if (_1724)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1731 = _1700 > 1;\n        bool _1738;\n        if (_1731)\n        {\n            _1738 = _1710 > _1159.fa_shadow_split.x;\n        }\n        else\n        {\n            _1738 = _1731;\n        }\n        if (_1738)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1744 = _1700 > 2;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1710 > _1159.fa_shadow_split.y;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1757 = _1700 > 3;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1710 > _1159.fa_shadow_split.z;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _419 [[buffer(1)]], constant fa_material& _2175 [[buffer(5)]], constant fa_shadows& _1159 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2782 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2782 = -_2782;\n    }\n    float3 _2467 = fast::normalize(_419.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n    Surface _2475 = fa_standard_surface(param_1, _419, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2813 = _2475.albedo;\n    float _2814 = _2475.alpha;\n    float3 _2815 = _2475.normal;\n    float _2816 = _2475.metallic;\n    float _2817 = _2475.roughness;\n    float _2818 = _2475.occlusion;\n    float3 _2819 = _2475.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n    Surface param_3 = _2475;\n    surface(param_2, param_3);\n    _2813 = param_3.albedo;\n    _2814 = param_3.alpha;\n    _2815 = param_3.normal;\n    _2816 = param_3.metallic;\n    _2817 = param_3.roughness;\n    _2818 = param_3.occlusion;\n    _2819 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2782;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _419, fa_decal_tex, fa_env_smp);\n    _2813 = param_6;\n    _2815 = param_7;\n    float3 result;\n    if (_419.fa_emissive.w > 0.5)\n    {\n        result = _2813;\n    }\n    else\n    {\n        float3 _2513 = _2815;\n        float3 _2514 = fast::normalize(_2513);\n        _2815 = _2514;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _2813, _2814, _2514, _2816, _2817, _2818, _2819 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _419, fa_env_smp, gl_FragCoord, _1159, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2175);\n    }\n    float3 _2529 = result;\n    float3 _2530 = _2529 + _2819;\n    result = _2530;\n    float3 param_10 = _2530;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1159);\n    bool _2539 = _419.fa_fog.w > 0.0;\n    bool _2547;\n    if (!_2539)\n    {\n        _2547 = _419.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2547 = _2539;\n    }\n    if (_2547)\n    {\n        float3 _2556 = in.fa_world_pos - _419.fa_camera_pos.xyz;\n        float _2563 = dot(_2556, _419.fa_fog_c.xyz);\n        bool _2567 = _419.fa_fog_c.w > 0.5;\n        float _2568;\n        if (_2567)\n        {\n            _2568 = _2563;\n        }\n        else\n        {\n            _2568 = length(_2556);\n        }\n        float _2580 = _2568 - _419.fa_fog_b.x;\n        if (_2580 > 0.0)\n        {\n            float _2589 = _419.fa_fog.w * _2580;\n            float tau = _2589 * _2589;\n            if (_419.fa_fog_b.y > 0.0)\n            {\n                float _2605;\n                if (_2567)\n                {\n                    _2605 = in.fa_world_pos.y - (_419.fa_fog_c.y * _2563);\n                }\n                else\n                {\n                    _2605 = _419.fa_camera_pos.y;\n                }\n                float _2626 = mix(_2605, in.fa_world_pos.y, fast::clamp(_419.fa_fog_b.x / _2568, 0.0, 1.0));\n                float _2630 = in.fa_world_pos.y - _2626;\n                float _2635 = _2626 - _419.fa_fog_b.z;\n                float _2640 = in.fa_world_pos.y - _419.fa_fog_b.z;\n                bool _2643 = _2635 <= 0.0;\n                bool _2644 = !_2643;\n                bool _2650;\n                if (_2644)\n                {\n                    _2650 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2650 = _2643;\n                }\n                float _2651;\n                if (_2650)\n                {\n                    _2651 = _419.fa_fog_b.y;\n                }\n                else\n                {\n                    _2651 = _419.fa_fog_b.y * exp(-fast::min(_419.fa_fog_b.w * _2635, 80.0));\n                }\n                bool _2678;\n                if (_2644)\n                {\n                    _2678 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2678 = _2643;\n                }\n                float _2679;\n                if (_2678)\n                {\n                    _2679 = _419.fa_fog_b.y * _2635;\n                }\n                else\n                {\n                    _2679 = (_419.fa_fog_b.y * (1.0 - exp(-fast::min(_419.fa_fog_b.w * _2635, 80.0)))) / _419.fa_fog_b.w;\n                }\n                bool _2704 = _2640 <= 0.0;\n                bool _2711;\n                if (!_2704)\n                {\n                    _2711 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2711 = _2704;\n                }\n                float _2712;\n                if (_2711)\n                {\n                    _2712 = _419.fa_fog_b.y * _2640;\n                }\n                else\n                {\n                    _2712 = (_419.fa_fog_b.y * (1.0 - exp(-fast::min(_419.fa_fog_b.w * _2640, 80.0)))) / _419.fa_fog_b.w;\n                }\n                float _2739;\n                if (abs(_2630) < 0.001000000047497451305389404296875)\n                {\n                    _2739 = _2651;\n                }\n                else\n                {\n                    _2739 = (_2712 - _2679) / _2630;\n                }\n                tau += (_2580 * fast::max(_2739, 0.0));\n            }\n            result = mix(result, _419.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2814);\n    return out;\n}\n\n",
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
            "inst_name": "_419",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1159",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2175",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    bool _424 = _419.fa_cl_info.x < 0.0;\n    bool _431;\n    if (!_424)\n    {\n        _431 = _419.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _431 = _424;\n    }\n    bool _439;\n    if (!_431)\n    {\n        _439 = _419.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _439 = _431;\n    }\n    bool _446;\n    if (!_439)\n    {\n        _446 = _419.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _446 = _439;\n    }\n    bool _453;\n    if (!_446)\n    {\n        _453 = _419.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    if (_453)\n    {\n        return float4(0.0);\n    }\n    float4 _463 = float4(world_pos, 1.0);\n    float _470 = dot(_419.fa_cl_vpw, _463);\n    if (!(_470 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _492 = float2(dot(_419.fa_cl_vpx, _463), dot(_419.fa_cl_vpy, _463)) / float2(_470);\n    int _496 = int(_419.fa_cl_grid.x);\n    int _500 = int(_419.fa_cl_grid.y);\n    int param = (int(_419.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_419.fa_cl_fwd.xyz, world_pos) + _419.fa_cl_fwd.w, _419.fa_cl_grid.w) / _419.fa_cl_grid.w) * _419.fa_cl_grid.z)), 0, int(_419.fa_cl_info.y) - 1) * _500) + clamp(int(floor(((_492.y * 0.5) + 0.5) * _419.fa_cl_grid.y)), 0, _500 - 1)) * _496)) + clamp(int(floor(((_492.x * 0.5) + 0.5) * _419.fa_cl_grid.x)), 0, _496 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    float3 param = world_pos;\n    float4 _576 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _419);\n    return int2(int(_576.x), int(_576.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_419.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2000 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _419);\n    fa_cl_slot = _2000.x;\n    fa_cl_local = _2000.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2236 = fa_linear_to_srgb(param);\n        c = _2236;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2244 = fa_srgb_to_linear(param_1);\n            c = _2244;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _199;\n    if (bool(i.front_facing))\n    {\n        _199 = i.world_normal;\n    }\n    else\n    {\n        _199 = -i.world_normal;\n    }\n    float3 _223 = fast::normalize(i.world_tangent.xyz - (_199 * dot(_199, i.world_tangent.xyz)));\n    float3 _251 = fast::normalize(((_223 * m.x) + ((cross(_199, _223) * i.world_tangent.w) * m.y)) + (_199 * m.z));\n    float3 _254;\n    if (bool(i.front_facing))\n    {\n        _254 = _251;\n    }\n    else\n    {\n        _254 = -_251;\n    }\n    return _254;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _419, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _419.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2275 = fa_tex_fix(param_2, param_3);\n    float4 _2982 = base_t;\n    _2982.x = _2275.x;\n    _2982.y = _2275.y;\n    _2982.z = _2275.z;\n    base_t = _2982;\n    float4 _2289 = (_2982 * _419.fa_base_color) * i.vertex_color;\n    float3 _2906 = i.world_normal;\n    if (_419.fa_maps.z > 0.5)\n    {\n        float param_4 = _419.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2321 = fa_tex_fix(param_6, param_7);\n        float3 _2324 = (_2321 * 2.0) - float3(1.0);\n        float2 _2329 = _2324.xy * _419.fa_maps.x;\n        float3 _2990 = _2324;\n        _2990.x = _2329.x;\n        _2990.y = _2329.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2990;\n        _2906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _419.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2358 = fa_tex_fix(param_12, param_13);\n    float4 _2993 = mrt;\n    _2993.x = _2358.x;\n    _2993.y = _2358.y;\n    _2993.z = _2358.z;\n    mrt = _2993;\n    float param_14 = _419.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _419.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2424 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2289.xyz, _2289.w, _2906, fast::clamp(_419.fa_pbr.x * _2358.z, 0.0, 1.0), fast::clamp(_419.fa_pbr.y * _2358.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_419.fa_maps.y * (_2397.x - 1.0)), _419.fa_emissive.xyz + (_419.fa_model_emissive.xyz * _2424) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _657 = rect.zw - rect.xy;\n    float2 _661 = _657 * atlas;\n    float2 _665 = ddx * _661;\n    float2 _669 = ddy * _661;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _657)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_665, _665), dot(_669, _669)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _704 = dfdx(world_pos);\n    float3 _707 = dfdy(world_pos);\n    bool _710 = _419.fa_counts.y < 0.5;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _419.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    if (_717)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _724 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _419);\n    int _728 = int(_724.w);\n    if (_728 < 1)\n    {\n        return;\n    }\n    int _738 = int(_419.fa_counts.y + 0.5);\n    int param_1 = _738;\n    float4 _742 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _745 = _742.yz;\n    int _749 = int(_742.w);\n    int param_2 = _738 + 1;\n    float4 _754 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _755 = _754.x;\n    int _761 = int(_419.fa_counts.w + 0.5) - 1;\n    int _765 = int(_724.z);\n    float3 _1031;\n    for (int k = 0; k < _728; k++)\n    {\n        int _778 = _765 + k;\n        int param_3 = _749 + (_778 >> 2);\n        int _796 = (_738 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_778 & 3]) * 7);\n        int param_4 = _796 + 6;\n        float4 _801 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_801.w + 0.5) >> _761) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _796;\n        float4 _816 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _796 + 1;\n        float4 _821 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _796 + 2;\n        float4 _826 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _829 = _816.xyz;\n        float _834 = dot(_829, world_pos) + _816.w;\n        float3 _836 = _821.xyz;\n        float _841 = dot(_836, world_pos) + _821.w;\n        float3 _843 = _826.xyz;\n        float _848 = dot(_843, world_pos) + _826.w;\n        bool _853 = abs(_834) > 0.5;\n        bool _861;\n        if (!_853)\n        {\n            _861 = abs(_841) > 0.5;\n        }\n        else\n        {\n            _861 = _853;\n        }\n        bool _869;\n        if (!_861)\n        {\n            _869 = abs(_848) > 0.5;\n        }\n        else\n        {\n            _869 = _861;\n        }\n        if (_869)\n        {\n            continue;\n        }\n        float _884 = fast::clamp(dot(geo_normal, fast::normalize(_843)) * _801.z, 0.0, 1.0);\n        if (_884 <= 0.0)\n        {\n            continue;\n        }\n        float _904 = (fast::clamp((0.5 - abs(_848)) * 10.0, 0.0, 1.0) * _884) * _801.x;\n        float2 _912 = float2(_834 + 0.5, 0.5 - _841);\n        float2 _922 = float2(dot(_829, _704), dot(_836, _704));\n        float2 _932 = float2(dot(_829, _707), dot(_836, _707));\n        int param_8 = _796 + 5;\n        float4 _937 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _796 + 3;\n        float4 _942 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _796 + 4;\n        float4 _947 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _937.xyz;\n        bool _957 = _942.z > _942.x;\n        if (_957)\n        {\n            float4 param_11 = _942;\n            float2 param_12 = _912;\n            float2 param_13 = _745;\n            float2 param_14 = _922;\n            float2 param_15 = _932;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_755 > 0.5) && (_755 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _983 = fa_dc_to_linear(param_16);\n                float4 _2944 = tx;\n                _2944.x = _983.x;\n                _2944.y = _983.y;\n                _2944.z = _983.z;\n                tx = _2944;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_904 * tex_a) * _937.w, 0.0, 1.0)));\n        if (_947.z > _947.x)\n        {\n            float4 param_17 = _947;\n            float2 param_18 = _912;\n            float2 param_19 = _745;\n            float2 param_20 = _922;\n            float2 param_21 = _932;\n            float4 _1027 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_755 > 1.5)\n            {\n                float3 param_22 = _1027.xyz;\n                float3 _1037 = fa_dc_to_srgb(param_22);\n                _1031 = _1037;\n            }\n            else\n            {\n                _1031 = _1027.xyz;\n            }\n            float3 _1047 = (_1031 * 2.0) - float3(1.0);\n            float2 _1052 = _1047.xy * _801.y;\n            float3 _1074 = (fast::normalize(_829) * _1052.x) + (fast::normalize(_836) * _1052.y);\n            float3 _1077 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1077, fast::normalize((_1077 * fast::max(_1047.z, 0.0500000007450580596923828125)) + (_1074 - (_1077 * dot(_1077, _1074)))), float3(fast::clamp(_904 * (_957 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419)\n{\n    int param = (int(_419.fa_cl_info.x) + int(_419.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _419);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _291 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _297 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _300 = _297.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _307 = _300 < 0.5;\n    float3 l;\n    if (_307)\n    {\n        l = fast::normalize(_291.xyz);\n    }\n    else\n    {\n        float3 _319 = _291.xyz - world_pos;\n        float _321 = length(_319);\n        dist = _321;\n        l = _319 / float3(fast::max(_321, 9.9999997473787516355514526367188e-05));\n        float _336 = _321 / fast::max(_291.w, 0.001000000047497451305389404296875);\n        float _342 = fast::clamp(1.0 - (_336 * _336), 0.0, 1.0);\n        atten = _342 * _342;\n        if (_300 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _356 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _366 = _356.w;\n            int param_3 = (li * 4) + 3;\n            float4 _373 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _374 = _373.x;\n            float cos_inner = _374;\n            if (_374 > 1.5)\n            {\n                cos_inner = mix(_366, 1.0, 0.25);\n            }\n            atten *= smoothstep(_366, cos_inner, dot(-l, fast::normalize(_356.xyz)));\n        }\n    }\n    int _405;\n    if (_307)\n    {\n        _405 = 0;\n    }\n    else\n    {\n        _405 = (_300 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _297.xyz * atten, atten, 1.0, dist, _405 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2085 = n < 0;\n    bool _2092;\n    if (!_2085)\n    {\n        _2092 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2092 = _2085;\n    }\n    if (_2092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1159)\n{\n    float _1149;\n    if (i == 0)\n    {\n        _1149 = _1159.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1165;\n        if (i == 1)\n        {\n            _1165 = _1159.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1173;\n            if (i == 2)\n            {\n                _1173 = _1159.fa_shadow_split.z;\n            }\n            else\n            {\n                _1173 = _1159.fa_shadow_split.w;\n            }\n            _1165 = _1173;\n        }\n        _1149 = _1165;\n    }\n    return _1149;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1137 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1137), sin(_1137)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex)\n{\n    float _1211 = fast::max(_1159.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1216 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1222 = sqrt(1.0 - (_1216 * _1216));\n    float _1229 = fast::min(_1222 / fast::max(_1216, 0.20000000298023223876953125), 4.0);\n    float _1234;\n    if (_1159.fa_shadow_bias.y > 0.0)\n    {\n        _1234 = _1159.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1234 = 1.5 * _1159.fa_shadow_info[ci].x;\n    }\n    float4 _1259 = _1159.fa_shadow_mat[ci] * float4(world + (n * (_1234 * _1222)), 1.0);\n    float _1266 = _1259.x;\n    bool _1269 = _1266 < _1159.fa_shadow_rect[ci].x;\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1266 > _1159.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1259.y < _1159.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1296;\n    if (!_1287)\n    {\n        _1296 = _1259.y > _1159.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1296 = _1287;\n    }\n    bool _1303;\n    if (!_1296)\n    {\n        _1303 = _1259.z > 1.0;\n    }\n    else\n    {\n        _1303 = _1296;\n    }\n    if (_1303)\n    {\n        return -1.0;\n    }\n    float _1312;\n    if (_1159.fa_shadow_bias.x > 0.0)\n    {\n        _1312 = _1159.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1312 = 1.5 * _1159.fa_shadow_info[ci].x;\n    }\n    float _1331 = _1259.z - ((_1312 * (1.0 + (0.5 * _1229))) / _1211);\n    float _1340 = ((_1159.fa_shadow_info[ci].x * fast::min(_1229, 3.0)) * 0.5) / _1211;\n    int _1349 = int(_1159.fa_shadow_cfg.z + 0.5);\n    if (_1349 == 1)\n    {\n        float2 param = _1259.xy;\n        float4 param_1 = _1159.fa_shadow_rect[ci];\n        float _1360 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1331 <= _1360);\n    }\n    float _1367 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1370 = _1349 == 2;\n    if (_1370)\n    {\n        float _1384 = fast::clamp(((_1159.fa_shadow_cfg.w * _1211) * 0.25) / _1159.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1367;\n            float2 _1403 = fa_shadow_vogel(param_2, param_3, param_4) * _1384;\n            float2 param_5 = _1259.xy + (_1403 * _1159.fa_shadow_bias.zw);\n            float4 param_6 = _1159.fa_shadow_rect[ci];\n            float _1414 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1414 < (_1331 - (length(_1403) * _1340)))\n            {\n                sum += _1414;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1331 - (sum / cnt), 0.0) * _1211) * _1159.fa_shadow_cfg.w) / _1159.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1458 = _1370 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1458; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1458;\n        float param_9 = _1367;\n        float2 _1477 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1259.xy + (_1477 * _1159.fa_shadow_bias.zw);\n        float4 param_11 = _1159.fa_shadow_rect[ci];\n        float _1488 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1331 - (length(_1477) * _1340)) <= _1488);\n    }\n    return lit / float(_1458);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex)\n{\n    if (_419.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1518 = int(_1159.fa_shadow_cfg.x + 0.5);\n    if (_1518 < 1)\n    {\n        return 1.0;\n    }\n    float _1533 = dot(world - _1159.fa_shadow_eye.xyz, _1159.fa_shadow_fwd.xyz);\n    int param = _1518 - 1;\n    if (_1533 > fa_shadow_split_at(param, _1159))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1545 = _1518 > 1;\n    bool _1552;\n    if (_1545)\n    {\n        _1552 = _1533 > _1159.fa_shadow_split.x;\n    }\n    else\n    {\n        _1552 = _1545;\n    }\n    if (_1552)\n    {\n        ci = 1;\n    }\n    bool _1556 = _1518 > 2;\n    bool _1563;\n    if (_1556)\n    {\n        _1563 = _1533 > _1159.fa_shadow_split.y;\n    }\n    else\n    {\n        _1563 = _1556;\n    }\n    if (_1563)\n    {\n        ci = 2;\n    }\n    bool _1567 = _1518 > 3;\n    bool _1574;\n    if (_1567)\n    {\n        _1574 = _1533 > _1159.fa_shadow_split.z;\n    }\n    else\n    {\n        _1574 = _1567;\n    }\n    if (_1574)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1518)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1600 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1159, fa_shadow_tex);\n        s = _1600;\n        if (_1600 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1159.fa_shadow_cfg.y > 0.0)\n    {\n        float _1625;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1625 = fa_shadow_split_at(param_5, _1159);\n        }\n        else\n        {\n            _1625 = _1159.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1644 = _1159.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1159) - _1625, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1655 = fast::clamp((_1533 - (fa_shadow_split_at(param_7, _1159) - _1644)) / _1644, 0.0, 1.0);\n        if (_1655 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1518)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1676 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1159, fa_shadow_tex);\n                s2 = _1676;\n                if (_1676 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1655);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2028 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2882 = _2028.direction;\n    float3 _2877 = _2028.color;\n    float _2879 = _2028.shadow;\n    int _2887 = _2028.type;\n    if ((_2887 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2882;\n        float _2042 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos);\n        _2879 = _2042;\n        _2877 *= _2042;\n    }\n    return LightSample{ _2882, _2877, _2028.attenuation, _2879, _2028._distance, _2887 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2059 = n < 0;\n    bool _2066;\n    if (!_2059)\n    {\n        _2066 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2066 = _2059;\n    }\n    if (_2066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1888 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1891 = _1888.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1891 * _1891, exp2((-9.27999973297119140625) * ndv)) * _1891) + _1888.y)) + _1888.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_419.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _419.fa_env_horizon.w)).xyz;\n    }\n    float _1812 = rough * rough;\n    float _1842 = 0.60000002384185791015625 * _1812;\n    return mix(mix(_419.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_419.fa_env_horizon.xyz, _419.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1812)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1842, 0.0500000007450580596923828125 + _1842, d.y))), ((_419.fa_env_sky.xyz + _419.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1812 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1930 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _419, fa_env_smp, fa_env_tex) * ((f0 * _1930.x) + float3(_1930.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _419, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _419, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _419, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1159, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2175)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2132 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2132 > bestPower)\n        {\n            bestPower = _2132;\n            best = n;\n        }\n    }\n    float3 lit = (_419.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2161 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _419, gl_FragCoord, _1159, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2169;\n        if (dot(s.normal, _2161.direction) > 0.5)\n        {\n            _2169 = 1.0;\n        }\n        else\n        {\n            _2169 = _2175.dark;\n        }\n        lit += ((s.albedo * _2161.color) * _2169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _419, fa_env_smp, fa_env_tex) * _2175.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1159)\n{\n    if (_1159.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1700 = int(_1159.fa_shadow_cfg.x + 0.5);\n    float _1710 = dot(world - _1159.fa_shadow_eye.xyz, _1159.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1715 = _1700 > 0;\n    bool _1724;\n    if (_1715)\n    {\n        int param = _1700 - 1;\n        _1724 = _1710 <= fa_shadow_split_at(param, _1159);\n    }\n    else\n    {\n        _1724 = _1715;\n    }\n    if (_1724)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1731 = _1700 > 1;\n        bool _1738;\n        if (_1731)\n        {\n            _1738 = _1710 > _1159.fa_shadow_split.x;\n        }\n        else\n        {\n            _1738 = _1731;\n        }\n        if (_1738)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1744 = _1700 > 2;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1710 > _1159.fa_shadow_split.y;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1757 = _1700 > 3;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1710 > _1159.fa_shadow_split.z;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _419 [[buffer(1)]], constant fa_material& _2175 [[buffer(5)]], constant fa_shadows& _1159 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2782 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2782 = -_2782;\n    }\n    float3 _2467 = fast::normalize(_419.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _419, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n    Surface _2475 = fa_standard_surface(param_1, _419, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2813 = _2475.albedo;\n    float _2814 = _2475.alpha;\n    float3 _2815 = _2475.normal;\n    float _2816 = _2475.metallic;\n    float _2817 = _2475.roughness;\n    float _2818 = _2475.occlusion;\n    float3 _2819 = _2475.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n    Surface param_3 = _2475;\n    surface(param_2, param_3);\n    _2813 = param_3.albedo;\n    _2814 = param_3.alpha;\n    _2815 = param_3.normal;\n    _2816 = param_3.metallic;\n    _2817 = param_3.roughness;\n    _2818 = param_3.occlusion;\n    _2819 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2782;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _419, fa_decal_tex, fa_env_smp);\n    _2813 = param_6;\n    _2815 = param_7;\n    float3 result;\n    if (_419.fa_emissive.w > 0.5)\n    {\n        result = _2813;\n    }\n    else\n    {\n        float3 _2513 = _2815;\n        float3 _2514 = fast::normalize(_2513);\n        _2815 = _2514;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _2782, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2467, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _2813, _2814, _2514, _2816, _2817, _2818, _2819 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _419, fa_env_smp, gl_FragCoord, _1159, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2175);\n    }\n    float3 _2529 = result;\n    float3 _2530 = _2529 + _2819;\n    result = _2530;\n    float3 param_10 = _2530;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1159);\n    bool _2539 = _419.fa_fog.w > 0.0;\n    bool _2547;\n    if (!_2539)\n    {\n        _2547 = _419.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2547 = _2539;\n    }\n    if (_2547)\n    {\n        float3 _2556 = in.fa_world_pos - _419.fa_camera_pos.xyz;\n        float _2563 = dot(_2556, _419.fa_fog_c.xyz);\n        bool _2567 = _419.fa_fog_c.w > 0.5;\n        float _2568;\n        if (_2567)\n        {\n            _2568 = _2563;\n        }\n        else\n        {\n            _2568 = length(_2556);\n        }\n        float _2580 = _2568 - _419.fa_fog_b.x;\n        if (_2580 > 0.0)\n        {\n            float _2589 = _419.fa_fog.w * _2580;\n            float tau = _2589 * _2589;\n            if (_419.fa_fog_b.y > 0.0)\n            {\n                float _2605;\n                if (_2567)\n                {\n                    _2605 = in.fa_world_pos.y - (_419.fa_fog_c.y * _2563);\n                }\n                else\n                {\n                    _2605 = _419.fa_camera_pos.y;\n                }\n                float _2626 = mix(_2605, in.fa_world_pos.y, fast::clamp(_419.fa_fog_b.x / _2568, 0.0, 1.0));\n                float _2630 = in.fa_world_pos.y - _2626;\n                float _2635 = _2626 - _419.fa_fog_b.z;\n                float _2640 = in.fa_world_pos.y - _419.fa_fog_b.z;\n                bool _2643 = _2635 <= 0.0;\n                bool _2644 = !_2643;\n                bool _2650;\n                if (_2644)\n                {\n                    _2650 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2650 = _2643;\n                }\n                float _2651;\n                if (_2650)\n                {\n                    _2651 = _419.fa_fog_b.y;\n                }\n                else\n                {\n                    _2651 = _419.fa_fog_b.y * exp(-fast::min(_419.fa_fog_b.w * _2635, 80.0));\n                }\n                bool _2678;\n                if (_2644)\n                {\n                    _2678 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2678 = _2643;\n                }\n                float _2679;\n                if (_2678)\n                {\n                    _2679 = _419.fa_fog_b.y * _2635;\n                }\n                else\n                {\n                    _2679 = (_419.fa_fog_b.y * (1.0 - exp(-fast::min(_419.fa_fog_b.w * _2635, 80.0)))) / _419.fa_fog_b.w;\n                }\n                bool _2704 = _2640 <= 0.0;\n                bool _2711;\n                if (!_2704)\n                {\n                    _2711 = _419.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2711 = _2704;\n                }\n                float _2712;\n                if (_2711)\n                {\n                    _2712 = _419.fa_fog_b.y * _2640;\n                }\n                else\n                {\n                    _2712 = (_419.fa_fog_b.y * (1.0 - exp(-fast::min(_419.fa_fog_b.w * _2640, 80.0)))) / _419.fa_fog_b.w;\n                }\n                float _2739;\n                if (abs(_2630) < 0.001000000047497451305389404296875)\n                {\n                    _2739 = _2651;\n                }\n                else\n                {\n                    _2739 = (_2712 - _2679) / _2630;\n                }\n                tau += (_2580 * fast::max(_2739, 0.0));\n            }\n            result = mix(result, _419.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2814);\n    return out;\n}\n\n",
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
            "inst_name": "_419",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1159",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2175",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
