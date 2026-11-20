{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "metal_macos",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _160)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _63.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _63, constant fa_mesh_vs_params& _160, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _160);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _63);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _160.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _160 [[buffer(0)]], constant fa_material_vs& _63 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_height, fa_vs_height_smp, _63, _160, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    bool _390 = _385.fa_cl_info.x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = _385.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = _385.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = _385.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = _385.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return int2(0);\n    }\n    float4 _429 = float4(world_pos, 1.0);\n    float _436 = dot(_385.fa_cl_vpw, _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _458 = float2(dot(_385.fa_cl_vpx, _429), dot(_385.fa_cl_vpy, _429)) / float2(_436);\n    int _462 = int(_385.fa_cl_grid.x);\n    int _466 = int(_385.fa_cl_grid.y);\n    int param = (int(_385.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_385.fa_cl_fwd.xyz, world_pos) + _385.fa_cl_fwd.w, _385.fa_cl_grid.w) / _385.fa_cl_grid.w) * _385.fa_cl_grid.z)), 0, int(_385.fa_cl_info.y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * _385.fa_cl_grid.y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * _385.fa_cl_grid.x)), 0, _462 - 1);\n    float4 _537 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_537.x), int(_537.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_385.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1440 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _385);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1555 = fa_linear_to_srgb(param);\n        c = _1555;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1563 = fa_srgb_to_linear(param_1);\n            c = _1563;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _157;\n    if (bool(i.front_facing))\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    float3 _181 = fast::normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    float3 _209 = fast::normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    float3 _212;\n    if (bool(i.front_facing))\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _385, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _385.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1594 = fa_tex_fix(param_2, param_3);\n    float4 _2391 = base_t;\n    _2391.x = _1594.x;\n    _2391.y = _1594.y;\n    _2391.z = _1594.z;\n    base_t = _2391;\n    float4 _1608 = (_2391 * _385.fa_base_color) * i.vertex_color;\n    float3 _2350 = i.world_normal;\n    if (_385.fa_maps.z > 0.5)\n    {\n        float param_4 = _385.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1640 = fa_tex_fix(param_6, param_7);\n        float3 _1644 = (_1640 * 2.0) - float3(1.0);\n        float2 _1649 = _1644.xy * _385.fa_maps.x;\n        float3 _2399 = _1644;\n        _2399.x = _1649.x;\n        _2399.y = _1649.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2399;\n        _2350 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _385.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1678 = fa_tex_fix(param_12, param_13);\n    float4 _2402 = mrt;\n    _2402.x = _1678.x;\n    _2402.y = _1678.y;\n    _2402.z = _1678.z;\n    mrt = _2402;\n    float param_14 = _385.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1717 = fa_tex_fix(param_16, param_17);\n    float param_18 = _385.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1744 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1608.xyz, _1608.w, _2350, fast::clamp(_385.fa_pbr.x * _1678.z, 0.0, 1.0), fast::clamp(_385.fa_pbr.y * _1678.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_385.fa_maps.y * (_1717.x - 1.0)), _385.fa_emissive.xyz + (_385.fa_model_emissive.xyz * _1744) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _385, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _385.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    int param = (int(_385.fa_cl_info.x) + int(_385.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _385);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _257 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _263 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    float3 l;\n    if (_273)\n    {\n        l = fast::normalize(_257.xyz);\n    }\n    else\n    {\n        float3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / float3(fast::max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / fast::max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = fast::clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _322 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            float4 _339 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, fast::normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _263.xyz * atten, atten, 1.0, dist, _371 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _621)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = _621.fa_shadow_split.x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = _621.fa_shadow_split.y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = _621.fa_shadow_split.z;\n            }\n            else\n            {\n                _635 = _621.fa_shadow_split.w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    float _673 = fast::max(_621.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _678 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = fast::min(_684 / fast::max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (_621.fa_shadow_bias.y > 0.0)\n    {\n        _697 = _621.fa_shadow_bias.y;\n    }\n    else\n    {\n        _697 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float4 _722 = _621.fa_shadow_mat[ci] * float4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < _621.fa_shadow_rect[ci].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > _621.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < _621.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > _621.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (_621.fa_shadow_bias.x > 0.0)\n    {\n        _775 = _621.fa_shadow_bias.x;\n    }\n    else\n    {\n        _775 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((_621.fa_shadow_info[ci].x * fast::min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(_621.fa_shadow_cfg.z + 0.5);\n    if (_812 == 1)\n    {\n        float2 param = _722.xy;\n        float4 param_1 = _621.fa_shadow_rect[ci];\n        float _823 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = fast::clamp(((_621.fa_shadow_cfg.w * _673) * 0.25) / _621.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            float2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            float2 param_5 = _722.xy + (_866 * _621.fa_shadow_bias.zw);\n            float4 param_6 = _621.fa_shadow_rect[ci];\n            float _877 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_794 - (sum / cnt), 0.0) * _673) * _621.fa_shadow_cfg.w) / _621.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        float2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _722.xy + (_940 * _621.fa_shadow_bias.zw);\n        float4 param_11 = _621.fa_shadow_rect[ci];\n        float _951 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    if (_385.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(_621.fa_shadow_cfg.x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param, _621))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > _621.fa_shadow_split.x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > _621.fa_shadow_split.y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > _621.fa_shadow_split.z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_621.fa_shadow_cfg.y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5, _621);\n        }\n        else\n        {\n            _1089 = _621.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1108 = _621.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _621) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = fast::clamp((_997 - (fa_shadow_split_at(param_7, _621) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2335 = _1468.direction;\n    float3 _2330 = _1468.color;\n    float _2332 = _1468.shadow;\n    int _2340 = _1468.type;\n    if ((_2340 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2335;\n        float _1482 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, fa_world_pos);\n        _2332 = _1482;\n        _2330 *= _1482;\n    }\n    return LightSample{ _2335, _2330, _1468.attenuation, _2332, _1468._distance, _2340 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1372 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _385.fa_env_horizon.w)).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(_385.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_385.fa_env_horizon.xyz, _385.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((_385.fa_env_sky.xyz + _385.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1277 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1414 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _385, fa_env_tex, fa_env_smp) * ((f0 * _1414.x) + float3(_1414.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _621)\n{\n    if (_621.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(_621.fa_shadow_cfg.x + 0.5);\n    float _1174 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param, _621);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > _621.fa_shadow_split.x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > _621.fa_shadow_split.y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > _621.fa_shadow_split.z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _385 [[buffer(1)]], constant fa_shadows& _621 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2255 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2255 = -_2255;\n    }\n    float3 _1787 = fast::normalize(_385.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2255, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1787, short(gl_FrontFacing) };\n    Surface _1795 = fa_standard_surface(param_1, _385, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2278 = _1795.albedo;\n    float _2279 = _1795.alpha;\n    float3 _2280 = _1795.normal;\n    float _2281 = _1795.metallic;\n    float _2282 = _1795.roughness;\n    float _2283 = _1795.occlusion;\n    float3 _2284 = _1795.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2255, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1787, short(gl_FrontFacing) };\n    Surface param_3 = _1795;\n    surface(param_2, param_3, height, height_smp);\n    _2278 = param_3.albedo;\n    _2279 = param_3.alpha;\n    _2280 = param_3.normal;\n    _2281 = param_3.metallic;\n    _2282 = param_3.roughness;\n    _2283 = param_3.occlusion;\n    _2284 = param_3.emission;\n    float3 result;\n    if (_385.fa_emissive.w > 0.5)\n    {\n        result = _2278;\n    }\n    else\n    {\n        float3 _1817 = fast::normalize(_2280);\n        float _1824 = fast::clamp(_2281, 0.0, 1.0);\n        float _1828 = fast::clamp(_2282, 0.0500000007450580596923828125, 1.0);\n        float _1832 = _1828 * _1828;\n        float _1836 = _1832 * _1832;\n        float _1841 = fast::max(dot(_1817, _1787), 9.9999997473787516355514526367188e-05);\n        float3 _1847 = _2278 * (1.0 - _1824);\n        float3 _1855 = mix(float3(0.039999999105930328369140625), _2278, float3(_1824));\n        float3 param_4 = _1817;\n        float3 lit = (fa_ambient_light(param_4, _385, fa_env_smp, fa_irr_tex) * _1847) * _2283;\n        int _1868 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1868; ln++)\n        {\n            int param_5 = ln;\n            int _1881 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1881;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2255;\n            LightSample _1890 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, in.fa_world_pos);\n            float3 _2313 = _1890.direction;\n            float _1898 = fast::max(dot(_1817, _2313), 0.0);\n            float3 _1909 = fast::normalize(_2313 + _1787);\n            float _1914 = fast::max(dot(_1817, _1909), 0.0);\n            float _1927 = ((_1914 * _1914) * (_1836 - 1.0)) + 1.0;\n            int param_9 = _1881;\n            lit += (((_1847 + (((_1855 + ((float3(1.0) - _1855) * powr(1.0 - fast::max(dot(_1787, _1909), 0.0), 5.0))) * (((_1836 / ((3.1415927410125732421875 * _1927) * _1927)) * (0.5 / fast::max(mix((2.0 * _1898) * _1841, _1898 + _1841, _1832), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1898))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1898 * (_1890.attenuation * _1890.shadow)));\n        }\n        float3 param_10 = _1817;\n        float3 param_11 = _1787;\n        float3 param_12 = _1855;\n        float param_13 = _1828;\n        float3 _1996 = lit;\n        float3 _1997 = _1996 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _385, fa_env_tex, fa_env_smp) * _2283);\n        lit = _1997;\n        result = _1997;\n    }\n    float3 _2001 = result;\n    float3 _2002 = _2001 + _2284;\n    result = _2002;\n    float3 param_14 = _2002;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _621);\n    bool _2011 = _385.fa_fog.w > 0.0;\n    bool _2019;\n    if (!_2011)\n    {\n        _2019 = _385.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2019 = _2011;\n    }\n    if (_2019)\n    {\n        float3 _2028 = in.fa_world_pos - _385.fa_camera_pos.xyz;\n        float _2035 = dot(_2028, _385.fa_fog_c.xyz);\n        bool _2039 = _385.fa_fog_c.w > 0.5;\n        float _2040;\n        if (_2039)\n        {\n            _2040 = _2035;\n        }\n        else\n        {\n            _2040 = length(_2028);\n        }\n        float _2052 = _2040 - _385.fa_fog_b.x;\n        if (_2052 > 0.0)\n        {\n            float _2061 = _385.fa_fog.w * _2052;\n            float tau = _2061 * _2061;\n            if (_385.fa_fog_b.y > 0.0)\n            {\n                float _2077;\n                if (_2039)\n                {\n                    _2077 = in.fa_world_pos.y - (_385.fa_fog_c.y * _2035);\n                }\n                else\n                {\n                    _2077 = _385.fa_camera_pos.y;\n                }\n                float _2098 = mix(_2077, in.fa_world_pos.y, fast::clamp(_385.fa_fog_b.x / _2040, 0.0, 1.0));\n                float _2102 = in.fa_world_pos.y - _2098;\n                float _2107 = _2098 - _385.fa_fog_b.z;\n                float _2112 = in.fa_world_pos.y - _385.fa_fog_b.z;\n                bool _2115 = _2107 <= 0.0;\n                bool _2116 = !_2115;\n                bool _2122;\n                if (_2116)\n                {\n                    _2122 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2122 = _2115;\n                }\n                float _2123;\n                if (_2122)\n                {\n                    _2123 = _385.fa_fog_b.y;\n                }\n                else\n                {\n                    _2123 = _385.fa_fog_b.y * exp(-fast::min(_385.fa_fog_b.w * _2107, 80.0));\n                }\n                bool _2150;\n                if (_2116)\n                {\n                    _2150 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2150 = _2115;\n                }\n                float _2151;\n                if (_2150)\n                {\n                    _2151 = _385.fa_fog_b.y * _2107;\n                }\n                else\n                {\n                    _2151 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2107, 80.0)))) / _385.fa_fog_b.w;\n                }\n                bool _2176 = _2112 <= 0.0;\n                bool _2183;\n                if (!_2176)\n                {\n                    _2183 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2183 = _2176;\n                }\n                float _2184;\n                if (_2183)\n                {\n                    _2184 = _385.fa_fog_b.y * _2112;\n                }\n                else\n                {\n                    _2184 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2112, 80.0)))) / _385.fa_fog_b.w;\n                }\n                float _2211;\n                if (abs(_2102) < 0.001000000047497451305389404296875)\n                {\n                    _2211 = _2123;\n                }\n                else\n                {\n                    _2211 = (_2184 - _2151) / _2102;\n                }\n                tau += (_2052 * fast::max(_2211, 0.0));\n            }\n            result = mix(result, _385.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2279);\n    return out;\n}\n\n",
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
            "inst_name": "_385",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_621",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _212)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_212.fa_joint_rows[_203] * weights[i]);\n        r1 += (_212.fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212.fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _165)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _68.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _68, constant fa_mesh_vs_params& _165, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _165);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _68);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _165.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _165 [[buffer(0)]], constant fa_skin& _212 [[buffer(3)]], constant fa_material_vs& _68 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _212);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_height, fa_vs_height_smp, _68, _165, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    bool _390 = _385.fa_cl_info.x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = _385.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = _385.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = _385.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = _385.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return int2(0);\n    }\n    float4 _429 = float4(world_pos, 1.0);\n    float _436 = dot(_385.fa_cl_vpw, _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _458 = float2(dot(_385.fa_cl_vpx, _429), dot(_385.fa_cl_vpy, _429)) / float2(_436);\n    int _462 = int(_385.fa_cl_grid.x);\n    int _466 = int(_385.fa_cl_grid.y);\n    int param = (int(_385.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_385.fa_cl_fwd.xyz, world_pos) + _385.fa_cl_fwd.w, _385.fa_cl_grid.w) / _385.fa_cl_grid.w) * _385.fa_cl_grid.z)), 0, int(_385.fa_cl_info.y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * _385.fa_cl_grid.y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * _385.fa_cl_grid.x)), 0, _462 - 1);\n    float4 _537 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_537.x), int(_537.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_385.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1440 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _385);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1555 = fa_linear_to_srgb(param);\n        c = _1555;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1563 = fa_srgb_to_linear(param_1);\n            c = _1563;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _157;\n    if (bool(i.front_facing))\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    float3 _181 = fast::normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    float3 _209 = fast::normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    float3 _212;\n    if (bool(i.front_facing))\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _385, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _385.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1594 = fa_tex_fix(param_2, param_3);\n    float4 _2391 = base_t;\n    _2391.x = _1594.x;\n    _2391.y = _1594.y;\n    _2391.z = _1594.z;\n    base_t = _2391;\n    float4 _1608 = (_2391 * _385.fa_base_color) * i.vertex_color;\n    float3 _2350 = i.world_normal;\n    if (_385.fa_maps.z > 0.5)\n    {\n        float param_4 = _385.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1640 = fa_tex_fix(param_6, param_7);\n        float3 _1644 = (_1640 * 2.0) - float3(1.0);\n        float2 _1649 = _1644.xy * _385.fa_maps.x;\n        float3 _2399 = _1644;\n        _2399.x = _1649.x;\n        _2399.y = _1649.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2399;\n        _2350 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _385.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1678 = fa_tex_fix(param_12, param_13);\n    float4 _2402 = mrt;\n    _2402.x = _1678.x;\n    _2402.y = _1678.y;\n    _2402.z = _1678.z;\n    mrt = _2402;\n    float param_14 = _385.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1717 = fa_tex_fix(param_16, param_17);\n    float param_18 = _385.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1744 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1608.xyz, _1608.w, _2350, fast::clamp(_385.fa_pbr.x * _1678.z, 0.0, 1.0), fast::clamp(_385.fa_pbr.y * _1678.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_385.fa_maps.y * (_1717.x - 1.0)), _385.fa_emissive.xyz + (_385.fa_model_emissive.xyz * _1744) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _385, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _385.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    int param = (int(_385.fa_cl_info.x) + int(_385.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _385);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _257 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _263 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    float3 l;\n    if (_273)\n    {\n        l = fast::normalize(_257.xyz);\n    }\n    else\n    {\n        float3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / float3(fast::max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / fast::max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = fast::clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _322 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            float4 _339 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, fast::normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _263.xyz * atten, atten, 1.0, dist, _371 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _621)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = _621.fa_shadow_split.x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = _621.fa_shadow_split.y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = _621.fa_shadow_split.z;\n            }\n            else\n            {\n                _635 = _621.fa_shadow_split.w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    float _673 = fast::max(_621.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _678 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = fast::min(_684 / fast::max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (_621.fa_shadow_bias.y > 0.0)\n    {\n        _697 = _621.fa_shadow_bias.y;\n    }\n    else\n    {\n        _697 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float4 _722 = _621.fa_shadow_mat[ci] * float4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < _621.fa_shadow_rect[ci].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > _621.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < _621.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > _621.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (_621.fa_shadow_bias.x > 0.0)\n    {\n        _775 = _621.fa_shadow_bias.x;\n    }\n    else\n    {\n        _775 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((_621.fa_shadow_info[ci].x * fast::min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(_621.fa_shadow_cfg.z + 0.5);\n    if (_812 == 1)\n    {\n        float2 param = _722.xy;\n        float4 param_1 = _621.fa_shadow_rect[ci];\n        float _823 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = fast::clamp(((_621.fa_shadow_cfg.w * _673) * 0.25) / _621.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            float2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            float2 param_5 = _722.xy + (_866 * _621.fa_shadow_bias.zw);\n            float4 param_6 = _621.fa_shadow_rect[ci];\n            float _877 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_794 - (sum / cnt), 0.0) * _673) * _621.fa_shadow_cfg.w) / _621.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        float2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _722.xy + (_940 * _621.fa_shadow_bias.zw);\n        float4 param_11 = _621.fa_shadow_rect[ci];\n        float _951 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    if (_385.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(_621.fa_shadow_cfg.x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param, _621))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > _621.fa_shadow_split.x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > _621.fa_shadow_split.y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > _621.fa_shadow_split.z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_621.fa_shadow_cfg.y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5, _621);\n        }\n        else\n        {\n            _1089 = _621.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1108 = _621.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _621) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = fast::clamp((_997 - (fa_shadow_split_at(param_7, _621) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2335 = _1468.direction;\n    float3 _2330 = _1468.color;\n    float _2332 = _1468.shadow;\n    int _2340 = _1468.type;\n    if ((_2340 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2335;\n        float _1482 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, fa_world_pos);\n        _2332 = _1482;\n        _2330 *= _1482;\n    }\n    return LightSample{ _2335, _2330, _1468.attenuation, _2332, _1468._distance, _2340 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1372 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _385.fa_env_horizon.w)).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(_385.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_385.fa_env_horizon.xyz, _385.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((_385.fa_env_sky.xyz + _385.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1277 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1414 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _385, fa_env_tex, fa_env_smp) * ((f0 * _1414.x) + float3(_1414.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _621)\n{\n    if (_621.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(_621.fa_shadow_cfg.x + 0.5);\n    float _1174 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param, _621);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > _621.fa_shadow_split.x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > _621.fa_shadow_split.y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > _621.fa_shadow_split.z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _385 [[buffer(1)]], constant fa_shadows& _621 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2255 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2255 = -_2255;\n    }\n    float3 _1787 = fast::normalize(_385.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2255, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1787, short(gl_FrontFacing) };\n    Surface _1795 = fa_standard_surface(param_1, _385, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2278 = _1795.albedo;\n    float _2279 = _1795.alpha;\n    float3 _2280 = _1795.normal;\n    float _2281 = _1795.metallic;\n    float _2282 = _1795.roughness;\n    float _2283 = _1795.occlusion;\n    float3 _2284 = _1795.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2255, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1787, short(gl_FrontFacing) };\n    Surface param_3 = _1795;\n    surface(param_2, param_3, height, height_smp);\n    _2278 = param_3.albedo;\n    _2279 = param_3.alpha;\n    _2280 = param_3.normal;\n    _2281 = param_3.metallic;\n    _2282 = param_3.roughness;\n    _2283 = param_3.occlusion;\n    _2284 = param_3.emission;\n    float3 result;\n    if (_385.fa_emissive.w > 0.5)\n    {\n        result = _2278;\n    }\n    else\n    {\n        float3 _1817 = fast::normalize(_2280);\n        float _1824 = fast::clamp(_2281, 0.0, 1.0);\n        float _1828 = fast::clamp(_2282, 0.0500000007450580596923828125, 1.0);\n        float _1832 = _1828 * _1828;\n        float _1836 = _1832 * _1832;\n        float _1841 = fast::max(dot(_1817, _1787), 9.9999997473787516355514526367188e-05);\n        float3 _1847 = _2278 * (1.0 - _1824);\n        float3 _1855 = mix(float3(0.039999999105930328369140625), _2278, float3(_1824));\n        float3 param_4 = _1817;\n        float3 lit = (fa_ambient_light(param_4, _385, fa_env_smp, fa_irr_tex) * _1847) * _2283;\n        int _1868 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1868; ln++)\n        {\n            int param_5 = ln;\n            int _1881 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1881;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2255;\n            LightSample _1890 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, in.fa_world_pos);\n            float3 _2313 = _1890.direction;\n            float _1898 = fast::max(dot(_1817, _2313), 0.0);\n            float3 _1909 = fast::normalize(_2313 + _1787);\n            float _1914 = fast::max(dot(_1817, _1909), 0.0);\n            float _1927 = ((_1914 * _1914) * (_1836 - 1.0)) + 1.0;\n            int param_9 = _1881;\n            lit += (((_1847 + (((_1855 + ((float3(1.0) - _1855) * powr(1.0 - fast::max(dot(_1787, _1909), 0.0), 5.0))) * (((_1836 / ((3.1415927410125732421875 * _1927) * _1927)) * (0.5 / fast::max(mix((2.0 * _1898) * _1841, _1898 + _1841, _1832), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1898))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1898 * (_1890.attenuation * _1890.shadow)));\n        }\n        float3 param_10 = _1817;\n        float3 param_11 = _1787;\n        float3 param_12 = _1855;\n        float param_13 = _1828;\n        float3 _1996 = lit;\n        float3 _1997 = _1996 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _385, fa_env_tex, fa_env_smp) * _2283);\n        lit = _1997;\n        result = _1997;\n    }\n    float3 _2001 = result;\n    float3 _2002 = _2001 + _2284;\n    result = _2002;\n    float3 param_14 = _2002;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _621);\n    bool _2011 = _385.fa_fog.w > 0.0;\n    bool _2019;\n    if (!_2011)\n    {\n        _2019 = _385.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2019 = _2011;\n    }\n    if (_2019)\n    {\n        float3 _2028 = in.fa_world_pos - _385.fa_camera_pos.xyz;\n        float _2035 = dot(_2028, _385.fa_fog_c.xyz);\n        bool _2039 = _385.fa_fog_c.w > 0.5;\n        float _2040;\n        if (_2039)\n        {\n            _2040 = _2035;\n        }\n        else\n        {\n            _2040 = length(_2028);\n        }\n        float _2052 = _2040 - _385.fa_fog_b.x;\n        if (_2052 > 0.0)\n        {\n            float _2061 = _385.fa_fog.w * _2052;\n            float tau = _2061 * _2061;\n            if (_385.fa_fog_b.y > 0.0)\n            {\n                float _2077;\n                if (_2039)\n                {\n                    _2077 = in.fa_world_pos.y - (_385.fa_fog_c.y * _2035);\n                }\n                else\n                {\n                    _2077 = _385.fa_camera_pos.y;\n                }\n                float _2098 = mix(_2077, in.fa_world_pos.y, fast::clamp(_385.fa_fog_b.x / _2040, 0.0, 1.0));\n                float _2102 = in.fa_world_pos.y - _2098;\n                float _2107 = _2098 - _385.fa_fog_b.z;\n                float _2112 = in.fa_world_pos.y - _385.fa_fog_b.z;\n                bool _2115 = _2107 <= 0.0;\n                bool _2116 = !_2115;\n                bool _2122;\n                if (_2116)\n                {\n                    _2122 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2122 = _2115;\n                }\n                float _2123;\n                if (_2122)\n                {\n                    _2123 = _385.fa_fog_b.y;\n                }\n                else\n                {\n                    _2123 = _385.fa_fog_b.y * exp(-fast::min(_385.fa_fog_b.w * _2107, 80.0));\n                }\n                bool _2150;\n                if (_2116)\n                {\n                    _2150 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2150 = _2115;\n                }\n                float _2151;\n                if (_2150)\n                {\n                    _2151 = _385.fa_fog_b.y * _2107;\n                }\n                else\n                {\n                    _2151 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2107, 80.0)))) / _385.fa_fog_b.w;\n                }\n                bool _2176 = _2112 <= 0.0;\n                bool _2183;\n                if (!_2176)\n                {\n                    _2183 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2183 = _2176;\n                }\n                float _2184;\n                if (_2183)\n                {\n                    _2184 = _385.fa_fog_b.y * _2112;\n                }\n                else\n                {\n                    _2184 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2112, 80.0)))) / _385.fa_fog_b.w;\n                }\n                float _2211;\n                if (abs(_2102) < 0.001000000047497451305389404296875)\n                {\n                    _2211 = _2123;\n                }\n                else\n                {\n                    _2211 = (_2184 - _2151) / _2102;\n                }\n                tau += (_2052 * fast::max(_2211, 0.0));\n            }\n            result = mix(result, _385.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2279);\n    return out;\n}\n\n",
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
            "inst_name": "_385",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_621",
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
