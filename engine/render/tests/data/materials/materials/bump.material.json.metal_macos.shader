{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "52eeaf5ca947e177a667baaefefbdd9e30bcf8f98f8759d8120ce8dc6aae8b9c",
  "slang": "metal_macos",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _160)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _63.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63, constant fa_mesh_vs_params& _160, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _160);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _63);\n    float4 _200 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _160.fa_light_vp * _200;\n    gl_Position = _160.fa_view_proj * _200;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _160 [[buffer(0)]], constant fa_material_vs& _63 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_height, fa_vs_height_smp, _63, _160, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354)\n{\n    bool _359 = _354.fa_cl_info.x < 0.0;\n    bool _366;\n    if (!_359)\n    {\n        _366 = _354.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _366 = _359;\n    }\n    bool _374;\n    if (!_366)\n    {\n        _374 = _354.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _374 = _366;\n    }\n    bool _381;\n    if (!_374)\n    {\n        _381 = _354.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _388;\n    if (!_381)\n    {\n        _388 = _354.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _388 = _381;\n    }\n    if (_388)\n    {\n        return int2(0);\n    }\n    float4 _398 = float4(world_pos, 1.0);\n    float _405 = dot(_354.fa_cl_vpw, _398);\n    if (!(_405 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _428 = float2(dot(_354.fa_cl_vpx, _398), dot(_354.fa_cl_vpy, _398)) / float2(_405);\n    int _432 = int(_354.fa_cl_grid.x);\n    int _436 = int(_354.fa_cl_grid.y);\n    int param = (int(_354.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_354.fa_cl_fwd.xyz, world_pos) + _354.fa_cl_fwd.w, _354.fa_cl_grid.w) / _354.fa_cl_grid.w) * _354.fa_cl_grid.z)), 0, int(_354.fa_cl_info.y) - 1) * _436) + clamp(int(floor(((_428.y * 0.5) + 0.5) * _354.fa_cl_grid.y)), 0, _436 - 1)) * _432)) + clamp(int(floor(((_428.x * 0.5) + 0.5) * _354.fa_cl_grid.x)), 0, _432 - 1);\n    float4 _507 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_507.x), int(_507.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_354.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _881 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _354);\n    fa_cl_slot = _881.x;\n    fa_cl_local = _881.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _996 = fa_linear_to_srgb(param);\n        c = _996;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1004 = fa_srgb_to_linear(param_1);\n            c = _1004;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _126;\n    if (bool(i.front_facing))\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = fast::normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = fast::normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (bool(i.front_facing))\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _354, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _354.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1036 = fa_tex_fix(param_2, param_3);\n    float4 _1830 = base_t;\n    _1830.x = _1036.x;\n    _1830.y = _1036.y;\n    _1830.z = _1036.z;\n    base_t = _1830;\n    float4 _1050 = (_1830 * _354.fa_base_color) * i.vertex_color;\n    float3 _1789 = i.world_normal;\n    if (_354.fa_maps.z > 0.5)\n    {\n        float param_4 = _354.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1083 = fa_tex_fix(param_6, param_7);\n        float3 _1086 = (_1083 * 2.0) - float3(1.0);\n        float2 _1091 = _1086.xy * _354.fa_maps.x;\n        float3 _1838 = _1086;\n        _1838.x = _1091.x;\n        _1838.y = _1091.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1838;\n        _1789 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _354.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1120 = fa_tex_fix(param_12, param_13);\n    float4 _1841 = mrt;\n    _1841.x = _1120.x;\n    _1841.y = _1120.y;\n    _1841.z = _1120.z;\n    mrt = _1841;\n    float param_14 = _354.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1159 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1186 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1050.xyz, _1050.w, _1789, fast::clamp(_354.fa_pbr.x * _1120.z, 0.0, 1.0), fast::clamp(_354.fa_pbr.y * _1120.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_354.fa_maps.y * (_1159.x - 1.0)), _354.fa_emissive.xyz + (_354.fa_model_emissive.xyz * _1186) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _354, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_354.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _354.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354)\n{\n    int param = (int(_354.fa_cl_info.x) + int(_354.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _354);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _235 = _232.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _242 = _235 < 0.5;\n    float3 l;\n    if (_242)\n    {\n        l = fast::normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / float3(fast::max(_256, 9.9999997473787516355514526367188e-05));\n        float _271 = _256 / fast::max(_226.w, 0.001000000047497451305389404296875);\n        float _277 = fast::clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (_235 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5)\n            {\n                cos_inner = mix(_301, 1.0, 0.25);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, fast::normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _232.xyz * atten, atten, 1.0, dist, _340 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex)\n{\n    if (_354.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _553 = coord.xyz / float3(coord.w);\n    float3 p = _553;\n    float2 suv = (_553.xy * 0.5) + float2(0.5);\n    if (_354.fa_counts.z > 0.5)\n    {\n        float3 _1810 = p;\n        _1810.z = (_1810.z * 0.5) + 0.5;\n        p = _1810;\n    }\n    else\n    {\n        float2 _1813 = suv;\n        _1813.y = 1.0 - _1813.y;\n        suv = _1813;\n    }\n    bool _579 = suv.x < 0.0;\n    bool _586;\n    if (!_579)\n    {\n        _586 = suv.x > 1.0;\n    }\n    else\n    {\n        _586 = _579;\n    }\n    bool _593;\n    if (!_586)\n    {\n        _593 = suv.y < 0.0;\n    }\n    else\n    {\n        _593 = _586;\n    }\n    bool _600;\n    if (!_593)\n    {\n        _600 = suv.y > 1.0;\n    }\n    else\n    {\n        _600 = _593;\n    }\n    bool _607;\n    if (!_600)\n    {\n        _607 = p.z > 1.0;\n    }\n    else\n    {\n        _607 = _600;\n    }\n    if (_607)\n    {\n        return 1.0;\n    }\n    float _622 = _354.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _622) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _354.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, fa_shadow_smp, _354, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _909 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _1774 = _909.direction;\n    float3 _1769 = _909.color;\n    float _1771 = _909.shadow;\n    int _1779 = _909.type;\n    if ((_1779 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1774;\n        float _923 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _354, fa_shadow_tex, fa_shadow_pos);\n        _1771 = _923;\n        _1769 *= _923;\n    }\n    return LightSample{ _1774, _1769, _909.attenuation, _1771, _909._distance, _1779 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _813 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _816 = _813.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_816 * _816, exp2((-9.27999973297119140625) * ndv)) * _816) + _813.y)) + _813.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _354, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_354.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _354.fa_env_horizon.w)).xyz;\n    }\n    float _716 = rough * rough;\n    float _747 = 0.60000002384185791015625 * _716;\n    return mix(mix(_354.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_354.fa_env_horizon.xyz, _354.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _716)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _747, 0.0500000007450580596923828125 + _747, d.y))), ((_354.fa_env_sky.xyz + _354.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_716 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _354, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _855 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _354, fa_env_tex, fa_env_smp) * ((f0 * _855.x) + float3(_855.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _354 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1694 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _1694 = -_1694;\n    }\n    float3 _1231 = fast::normalize(_354.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _354, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1694, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1231, short(gl_FrontFacing) };\n    Surface _1239 = fa_standard_surface(param_1, _354, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1717 = _1239.albedo;\n    float _1718 = _1239.alpha;\n    float3 _1719 = _1239.normal;\n    float _1720 = _1239.metallic;\n    float _1721 = _1239.roughness;\n    float _1722 = _1239.occlusion;\n    float3 _1723 = _1239.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _1694, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1231, short(gl_FrontFacing) };\n    Surface param_3 = _1239;\n    surface(param_2, param_3, height, height_smp);\n    _1717 = param_3.albedo;\n    _1718 = param_3.alpha;\n    _1719 = param_3.normal;\n    _1720 = param_3.metallic;\n    _1721 = param_3.roughness;\n    _1722 = param_3.occlusion;\n    _1723 = param_3.emission;\n    float3 result;\n    if (_354.fa_emissive.w > 0.5)\n    {\n        result = _1717;\n    }\n    else\n    {\n        float3 _1261 = fast::normalize(_1719);\n        float _1268 = fast::clamp(_1720, 0.0, 1.0);\n        float _1272 = fast::clamp(_1721, 0.0500000007450580596923828125, 1.0);\n        float _1276 = _1272 * _1272;\n        float _1280 = _1276 * _1276;\n        float _1285 = fast::max(dot(_1261, _1231), 9.9999997473787516355514526367188e-05);\n        float3 _1291 = _1717 * (1.0 - _1268);\n        float3 _1299 = mix(float3(0.039999999105930328369140625), _1717, float3(_1268));\n        float3 param_4 = _1261;\n        float3 lit = (fa_ambient_light(param_4, _354, fa_env_smp, fa_irr_tex) * _1291) * _1722;\n        int _1312 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1312; ln++)\n        {\n            int param_5 = ln;\n            int _1325 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _354, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1325;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _1694;\n            LightSample _1334 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _354, fa_shadow_tex, in.fa_shadow_pos);\n            float3 _1752 = _1334.direction;\n            float _1342 = fast::max(dot(_1261, _1752), 0.0);\n            float3 _1353 = fast::normalize(_1752 + _1231);\n            float _1358 = fast::max(dot(_1261, _1353), 0.0);\n            float _1371 = ((_1358 * _1358) * (_1280 - 1.0)) + 1.0;\n            int param_9 = _1325;\n            lit += (((_1291 + (((_1299 + ((float3(1.0) - _1299) * powr(1.0 - fast::max(dot(_1231, _1353), 0.0), 5.0))) * (((_1280 / ((3.1415927410125732421875 * _1371) * _1371)) * (0.5 / fast::max(mix((2.0 * _1342) * _1285, _1342 + _1285, _1276), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1342))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1342 * (_1334.attenuation * _1334.shadow)));\n        }\n        float3 param_10 = _1261;\n        float3 param_11 = _1231;\n        float3 param_12 = _1299;\n        float param_13 = _1272;\n        float3 _1440 = lit;\n        float3 _1441 = _1440 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _354, fa_env_tex, fa_env_smp) * _1722);\n        lit = _1441;\n        result = _1441;\n    }\n    result += _1723;\n    bool _1450 = _354.fa_fog.w > 0.0;\n    bool _1458;\n    if (!_1450)\n    {\n        _1458 = _354.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1458 = _1450;\n    }\n    if (_1458)\n    {\n        float3 _1467 = in.fa_world_pos - _354.fa_camera_pos.xyz;\n        float _1474 = dot(_1467, _354.fa_fog_c.xyz);\n        bool _1478 = _354.fa_fog_c.w > 0.5;\n        float _1479;\n        if (_1478)\n        {\n            _1479 = _1474;\n        }\n        else\n        {\n            _1479 = length(_1467);\n        }\n        float _1491 = _1479 - _354.fa_fog_b.x;\n        if (_1491 > 0.0)\n        {\n            float _1500 = _354.fa_fog.w * _1491;\n            float tau = _1500 * _1500;\n            if (_354.fa_fog_b.y > 0.0)\n            {\n                float _1516;\n                if (_1478)\n                {\n                    _1516 = in.fa_world_pos.y - (_354.fa_fog_c.y * _1474);\n                }\n                else\n                {\n                    _1516 = _354.fa_camera_pos.y;\n                }\n                float _1537 = mix(_1516, in.fa_world_pos.y, fast::clamp(_354.fa_fog_b.x / _1479, 0.0, 1.0));\n                float _1541 = in.fa_world_pos.y - _1537;\n                float _1546 = _1537 - _354.fa_fog_b.z;\n                float _1551 = in.fa_world_pos.y - _354.fa_fog_b.z;\n                bool _1554 = _1546 <= 0.0;\n                bool _1555 = !_1554;\n                bool _1561;\n                if (_1555)\n                {\n                    _1561 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1561 = _1554;\n                }\n                float _1562;\n                if (_1561)\n                {\n                    _1562 = _354.fa_fog_b.y;\n                }\n                else\n                {\n                    _1562 = _354.fa_fog_b.y * exp(-fast::min(_354.fa_fog_b.w * _1546, 80.0));\n                }\n                bool _1589;\n                if (_1555)\n                {\n                    _1589 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1589 = _1554;\n                }\n                float _1590;\n                if (_1589)\n                {\n                    _1590 = _354.fa_fog_b.y * _1546;\n                }\n                else\n                {\n                    _1590 = (_354.fa_fog_b.y * (1.0 - exp(-fast::min(_354.fa_fog_b.w * _1546, 80.0)))) / _354.fa_fog_b.w;\n                }\n                bool _1615 = _1551 <= 0.0;\n                bool _1622;\n                if (!_1615)\n                {\n                    _1622 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1622 = _1615;\n                }\n                float _1623;\n                if (_1622)\n                {\n                    _1623 = _354.fa_fog_b.y * _1551;\n                }\n                else\n                {\n                    _1623 = (_354.fa_fog_b.y * (1.0 - exp(-fast::min(_354.fa_fog_b.w * _1551, 80.0)))) / _354.fa_fog_b.w;\n                }\n                float _1650;\n                if (abs(_1541) < 0.001000000047497451305389404296875)\n                {\n                    _1650 = _1562;\n                }\n                else\n                {\n                    _1650 = (_1623 - _1590) / _1541;\n                }\n                tau += (_1491 * fast::max(_1650, 0.0));\n            }\n            result = mix(result, _354.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1718);\n    return out;\n}\n\n",
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
            "inst_name": "_63",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_354",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _212)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_212.fa_joint_rows[_203] * weights[i]);\n        r1 += (_212.fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212.fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _165)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _68.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68, constant fa_mesh_vs_params& _165, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _165);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _68);\n    float4 _313 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _165.fa_light_vp * _313;\n    gl_Position = _165.fa_view_proj * _313;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _165 [[buffer(0)]], constant fa_skin& _212 [[buffer(3)]], constant fa_material_vs& _68 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _212);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_height, fa_vs_height_smp, _68, _165, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354)\n{\n    bool _359 = _354.fa_cl_info.x < 0.0;\n    bool _366;\n    if (!_359)\n    {\n        _366 = _354.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _366 = _359;\n    }\n    bool _374;\n    if (!_366)\n    {\n        _374 = _354.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _374 = _366;\n    }\n    bool _381;\n    if (!_374)\n    {\n        _381 = _354.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _388;\n    if (!_381)\n    {\n        _388 = _354.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _388 = _381;\n    }\n    if (_388)\n    {\n        return int2(0);\n    }\n    float4 _398 = float4(world_pos, 1.0);\n    float _405 = dot(_354.fa_cl_vpw, _398);\n    if (!(_405 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _428 = float2(dot(_354.fa_cl_vpx, _398), dot(_354.fa_cl_vpy, _398)) / float2(_405);\n    int _432 = int(_354.fa_cl_grid.x);\n    int _436 = int(_354.fa_cl_grid.y);\n    int param = (int(_354.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_354.fa_cl_fwd.xyz, world_pos) + _354.fa_cl_fwd.w, _354.fa_cl_grid.w) / _354.fa_cl_grid.w) * _354.fa_cl_grid.z)), 0, int(_354.fa_cl_info.y) - 1) * _436) + clamp(int(floor(((_428.y * 0.5) + 0.5) * _354.fa_cl_grid.y)), 0, _436 - 1)) * _432)) + clamp(int(floor(((_428.x * 0.5) + 0.5) * _354.fa_cl_grid.x)), 0, _432 - 1);\n    float4 _507 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_507.x), int(_507.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_354.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _881 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _354);\n    fa_cl_slot = _881.x;\n    fa_cl_local = _881.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _996 = fa_linear_to_srgb(param);\n        c = _996;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1004 = fa_srgb_to_linear(param_1);\n            c = _1004;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _126;\n    if (bool(i.front_facing))\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = fast::normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = fast::normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (bool(i.front_facing))\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _354, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _354.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1036 = fa_tex_fix(param_2, param_3);\n    float4 _1830 = base_t;\n    _1830.x = _1036.x;\n    _1830.y = _1036.y;\n    _1830.z = _1036.z;\n    base_t = _1830;\n    float4 _1050 = (_1830 * _354.fa_base_color) * i.vertex_color;\n    float3 _1789 = i.world_normal;\n    if (_354.fa_maps.z > 0.5)\n    {\n        float param_4 = _354.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1083 = fa_tex_fix(param_6, param_7);\n        float3 _1086 = (_1083 * 2.0) - float3(1.0);\n        float2 _1091 = _1086.xy * _354.fa_maps.x;\n        float3 _1838 = _1086;\n        _1838.x = _1091.x;\n        _1838.y = _1091.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1838;\n        _1789 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _354.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1120 = fa_tex_fix(param_12, param_13);\n    float4 _1841 = mrt;\n    _1841.x = _1120.x;\n    _1841.y = _1120.y;\n    _1841.z = _1120.z;\n    mrt = _1841;\n    float param_14 = _354.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1159 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1186 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1050.xyz, _1050.w, _1789, fast::clamp(_354.fa_pbr.x * _1120.z, 0.0, 1.0), fast::clamp(_354.fa_pbr.y * _1120.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_354.fa_maps.y * (_1159.x - 1.0)), _354.fa_emissive.xyz + (_354.fa_model_emissive.xyz * _1186) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _354, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_354.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _354.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354)\n{\n    int param = (int(_354.fa_cl_info.x) + int(_354.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _354);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _235 = _232.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _242 = _235 < 0.5;\n    float3 l;\n    if (_242)\n    {\n        l = fast::normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / float3(fast::max(_256, 9.9999997473787516355514526367188e-05));\n        float _271 = _256 / fast::max(_226.w, 0.001000000047497451305389404296875);\n        float _277 = fast::clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (_235 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5)\n            {\n                cos_inner = mix(_301, 1.0, 0.25);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, fast::normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _232.xyz * atten, atten, 1.0, dist, _340 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex)\n{\n    if (_354.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _553 = coord.xyz / float3(coord.w);\n    float3 p = _553;\n    float2 suv = (_553.xy * 0.5) + float2(0.5);\n    if (_354.fa_counts.z > 0.5)\n    {\n        float3 _1810 = p;\n        _1810.z = (_1810.z * 0.5) + 0.5;\n        p = _1810;\n    }\n    else\n    {\n        float2 _1813 = suv;\n        _1813.y = 1.0 - _1813.y;\n        suv = _1813;\n    }\n    bool _579 = suv.x < 0.0;\n    bool _586;\n    if (!_579)\n    {\n        _586 = suv.x > 1.0;\n    }\n    else\n    {\n        _586 = _579;\n    }\n    bool _593;\n    if (!_586)\n    {\n        _593 = suv.y < 0.0;\n    }\n    else\n    {\n        _593 = _586;\n    }\n    bool _600;\n    if (!_593)\n    {\n        _600 = suv.y > 1.0;\n    }\n    else\n    {\n        _600 = _593;\n    }\n    bool _607;\n    if (!_600)\n    {\n        _607 = p.z > 1.0;\n    }\n    else\n    {\n        _607 = _600;\n    }\n    if (_607)\n    {\n        return 1.0;\n    }\n    float _622 = _354.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _622) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _354.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, fa_shadow_smp, _354, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _354, texture2d<float> fa_shadow_tex, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _909 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _1774 = _909.direction;\n    float3 _1769 = _909.color;\n    float _1771 = _909.shadow;\n    int _1779 = _909.type;\n    if ((_1779 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1774;\n        float _923 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _354, fa_shadow_tex, fa_shadow_pos);\n        _1771 = _923;\n        _1769 *= _923;\n    }\n    return LightSample{ _1774, _1769, _909.attenuation, _1771, _909._distance, _1779 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _813 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _816 = _813.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_816 * _816, exp2((-9.27999973297119140625) * ndv)) * _816) + _813.y)) + _813.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _354, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_354.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _354.fa_env_horizon.w)).xyz;\n    }\n    float _716 = rough * rough;\n    float _747 = 0.60000002384185791015625 * _716;\n    return mix(mix(_354.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_354.fa_env_horizon.xyz, _354.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _716)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _747, 0.0500000007450580596923828125 + _747, d.y))), ((_354.fa_env_sky.xyz + _354.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_716 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _354, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _855 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _354, fa_env_tex, fa_env_smp) * ((f0 * _855.x) + float3(_855.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _354 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1694 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _1694 = -_1694;\n    }\n    float3 _1231 = fast::normalize(_354.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _354, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1694, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1231, short(gl_FrontFacing) };\n    Surface _1239 = fa_standard_surface(param_1, _354, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1717 = _1239.albedo;\n    float _1718 = _1239.alpha;\n    float3 _1719 = _1239.normal;\n    float _1720 = _1239.metallic;\n    float _1721 = _1239.roughness;\n    float _1722 = _1239.occlusion;\n    float3 _1723 = _1239.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _1694, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1231, short(gl_FrontFacing) };\n    Surface param_3 = _1239;\n    surface(param_2, param_3, height, height_smp);\n    _1717 = param_3.albedo;\n    _1718 = param_3.alpha;\n    _1719 = param_3.normal;\n    _1720 = param_3.metallic;\n    _1721 = param_3.roughness;\n    _1722 = param_3.occlusion;\n    _1723 = param_3.emission;\n    float3 result;\n    if (_354.fa_emissive.w > 0.5)\n    {\n        result = _1717;\n    }\n    else\n    {\n        float3 _1261 = fast::normalize(_1719);\n        float _1268 = fast::clamp(_1720, 0.0, 1.0);\n        float _1272 = fast::clamp(_1721, 0.0500000007450580596923828125, 1.0);\n        float _1276 = _1272 * _1272;\n        float _1280 = _1276 * _1276;\n        float _1285 = fast::max(dot(_1261, _1231), 9.9999997473787516355514526367188e-05);\n        float3 _1291 = _1717 * (1.0 - _1268);\n        float3 _1299 = mix(float3(0.039999999105930328369140625), _1717, float3(_1268));\n        float3 param_4 = _1261;\n        float3 lit = (fa_ambient_light(param_4, _354, fa_env_smp, fa_irr_tex) * _1291) * _1722;\n        int _1312 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1312; ln++)\n        {\n            int param_5 = ln;\n            int _1325 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _354, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1325;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _1694;\n            LightSample _1334 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _354, fa_shadow_tex, in.fa_shadow_pos);\n            float3 _1752 = _1334.direction;\n            float _1342 = fast::max(dot(_1261, _1752), 0.0);\n            float3 _1353 = fast::normalize(_1752 + _1231);\n            float _1358 = fast::max(dot(_1261, _1353), 0.0);\n            float _1371 = ((_1358 * _1358) * (_1280 - 1.0)) + 1.0;\n            int param_9 = _1325;\n            lit += (((_1291 + (((_1299 + ((float3(1.0) - _1299) * powr(1.0 - fast::max(dot(_1231, _1353), 0.0), 5.0))) * (((_1280 / ((3.1415927410125732421875 * _1371) * _1371)) * (0.5 / fast::max(mix((2.0 * _1342) * _1285, _1342 + _1285, _1276), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1342))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1342 * (_1334.attenuation * _1334.shadow)));\n        }\n        float3 param_10 = _1261;\n        float3 param_11 = _1231;\n        float3 param_12 = _1299;\n        float param_13 = _1272;\n        float3 _1440 = lit;\n        float3 _1441 = _1440 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _354, fa_env_tex, fa_env_smp) * _1722);\n        lit = _1441;\n        result = _1441;\n    }\n    result += _1723;\n    bool _1450 = _354.fa_fog.w > 0.0;\n    bool _1458;\n    if (!_1450)\n    {\n        _1458 = _354.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1458 = _1450;\n    }\n    if (_1458)\n    {\n        float3 _1467 = in.fa_world_pos - _354.fa_camera_pos.xyz;\n        float _1474 = dot(_1467, _354.fa_fog_c.xyz);\n        bool _1478 = _354.fa_fog_c.w > 0.5;\n        float _1479;\n        if (_1478)\n        {\n            _1479 = _1474;\n        }\n        else\n        {\n            _1479 = length(_1467);\n        }\n        float _1491 = _1479 - _354.fa_fog_b.x;\n        if (_1491 > 0.0)\n        {\n            float _1500 = _354.fa_fog.w * _1491;\n            float tau = _1500 * _1500;\n            if (_354.fa_fog_b.y > 0.0)\n            {\n                float _1516;\n                if (_1478)\n                {\n                    _1516 = in.fa_world_pos.y - (_354.fa_fog_c.y * _1474);\n                }\n                else\n                {\n                    _1516 = _354.fa_camera_pos.y;\n                }\n                float _1537 = mix(_1516, in.fa_world_pos.y, fast::clamp(_354.fa_fog_b.x / _1479, 0.0, 1.0));\n                float _1541 = in.fa_world_pos.y - _1537;\n                float _1546 = _1537 - _354.fa_fog_b.z;\n                float _1551 = in.fa_world_pos.y - _354.fa_fog_b.z;\n                bool _1554 = _1546 <= 0.0;\n                bool _1555 = !_1554;\n                bool _1561;\n                if (_1555)\n                {\n                    _1561 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1561 = _1554;\n                }\n                float _1562;\n                if (_1561)\n                {\n                    _1562 = _354.fa_fog_b.y;\n                }\n                else\n                {\n                    _1562 = _354.fa_fog_b.y * exp(-fast::min(_354.fa_fog_b.w * _1546, 80.0));\n                }\n                bool _1589;\n                if (_1555)\n                {\n                    _1589 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1589 = _1554;\n                }\n                float _1590;\n                if (_1589)\n                {\n                    _1590 = _354.fa_fog_b.y * _1546;\n                }\n                else\n                {\n                    _1590 = (_354.fa_fog_b.y * (1.0 - exp(-fast::min(_354.fa_fog_b.w * _1546, 80.0)))) / _354.fa_fog_b.w;\n                }\n                bool _1615 = _1551 <= 0.0;\n                bool _1622;\n                if (!_1615)\n                {\n                    _1622 = _354.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1622 = _1615;\n                }\n                float _1623;\n                if (_1622)\n                {\n                    _1623 = _354.fa_fog_b.y * _1551;\n                }\n                else\n                {\n                    _1623 = (_354.fa_fog_b.y * (1.0 - exp(-fast::min(_354.fa_fog_b.w * _1551, 80.0)))) / _354.fa_fog_b.w;\n                }\n                float _1650;\n                if (abs(_1541) < 0.001000000047497451305389404296875)\n                {\n                    _1650 = _1562;\n                }\n                else\n                {\n                    _1650 = (_1623 - _1590) / _1541;\n                }\n                tau += (_1491 * fast::max(_1650, 0.0));\n            }\n            result = mix(result, _354.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1718);\n    return out;\n}\n\n",
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
            "inst_name": "_68",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_354",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _160)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _63.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63, constant fa_mesh_vs_params& _160, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _160);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _63);\n    float4 _204 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_160.fa_light_vp * _204).z;\n    fa_pre_r0 = float3(_160.fa_light_vp[0].x, _160.fa_light_vp[1].x, _160.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_160.fa_light_vp[0].y, _160.fa_light_vp[1].y, _160.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_160.fa_light_vp[0].z, _160.fa_light_vp[1].z, _160.fa_light_vp[2].z);\n    gl_Position = _160.fa_view_proj * _204;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _160 [[buffer(0)]], constant fa_material_vs& _63 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_height, fa_vs_height_smp, _63, _160, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _604 = base_t;\n    _604.x = _240.x;\n    _604.y = _240.y;\n    _604.z = _240.z;\n    base_t = _604;\n    float4 _256 = (_604 * _229.fa_base_color) * i.vertex_color;\n    float3 _585 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0) - float3(1.0);\n        float2 _298 = _293.xy * _229.fa_maps.x;\n        float3 _612 = _293;\n        _612.x = _298.x;\n        _612.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _615 = mrt;\n    _615.x = _327.x;\n    _615.y = _327.y;\n    _615.z = _327.z;\n    mrt = _615;\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    return Surface{ _256.xyz, _256.w, _585, fast::clamp(_229.fa_pbr.x * _327.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _327.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_368.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _395) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> height [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _532 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    float3 _441 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _532, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _441, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _532, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _441, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, height, height_smp);\n    float3 _456 = fast::normalize(param_2.normal);\n    float3 _471 = fast::normalize(float3(dot(in.fa_pre_r0, _456), dot(in.fa_pre_r1, _456), dot(in.fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / float2((abs(_471.x) + abs(_471.y)) + abs(_483));\n    if (_483 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_63",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _212)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_212.fa_joint_rows[_203] * weights[i]);\n        r1 += (_212.fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212.fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _165)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _68.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68, constant fa_mesh_vs_params& _165, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _165);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _68);\n    float4 _317 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_165.fa_light_vp * _317).z;\n    fa_pre_r0 = float3(_165.fa_light_vp[0].x, _165.fa_light_vp[1].x, _165.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_165.fa_light_vp[0].y, _165.fa_light_vp[1].y, _165.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_165.fa_light_vp[0].z, _165.fa_light_vp[1].z, _165.fa_light_vp[2].z);\n    gl_Position = _165.fa_view_proj * _317;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _165 [[buffer(0)]], constant fa_skin& _212 [[buffer(3)]], constant fa_material_vs& _68 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _212);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_height, fa_vs_height_smp, _68, _165, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _604 = base_t;\n    _604.x = _240.x;\n    _604.y = _240.y;\n    _604.z = _240.z;\n    base_t = _604;\n    float4 _256 = (_604 * _229.fa_base_color) * i.vertex_color;\n    float3 _585 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0) - float3(1.0);\n        float2 _298 = _293.xy * _229.fa_maps.x;\n        float3 _612 = _293;\n        _612.x = _298.x;\n        _612.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _615 = mrt;\n    _615.x = _327.x;\n    _615.y = _327.y;\n    _615.z = _327.z;\n    mrt = _615;\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    return Surface{ _256.xyz, _256.w, _585, fast::clamp(_229.fa_pbr.x * _327.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _327.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_368.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _395) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> height [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _532 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    float3 _441 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _532, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _441, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _532, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _441, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, height, height_smp);\n    float3 _456 = fast::normalize(param_2.normal);\n    float3 _471 = fast::normalize(float3(dot(in.fa_pre_r0, _456), dot(in.fa_pre_r1, _456), dot(in.fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / float2((abs(_471.x) + abs(_471.y)) + abs(_483));\n    if (_483 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_68",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _151)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * _151.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _54)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _54.lift);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _151 [[buffer(0)]], constant fa_material_vs& _54 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _151);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _54);\n    out.gl_Position = _151.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_54",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "msl_buffer_n": 0
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _203)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_203.fa_joint_rows[_194] * weights[i]);\n        r1 += (_203.fa_joint_rows[_194 + 1] * weights[i]);\n        r2 += (_203.fa_joint_rows[_194 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _156)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * _156.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _59)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _59.lift);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _156 [[buffer(0)]], constant fa_skin& _203 [[buffer(3)]], constant fa_material_vs& _59 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _203);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _156);\n    vertex0(param_8, fa_vs_height, fa_vs_height_smp, _59);\n    out.gl_Position = _156.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_59",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_203",
            "msl_buffer_n": 3
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    }
  }
}
