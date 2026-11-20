{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    bool _390 = _385.fa_cl_info.x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = _385.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = _385.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = _385.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = _385.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return int2(0);\n    }\n    float4 _429 = float4(world_pos, 1.0);\n    float _436 = dot(_385.fa_cl_vpw, _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _458 = float2(dot(_385.fa_cl_vpx, _429), dot(_385.fa_cl_vpy, _429)) / float2(_436);\n    int _462 = int(_385.fa_cl_grid.x);\n    int _466 = int(_385.fa_cl_grid.y);\n    int param = (int(_385.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_385.fa_cl_fwd.xyz, world_pos) + _385.fa_cl_fwd.w, _385.fa_cl_grid.w) / _385.fa_cl_grid.w) * _385.fa_cl_grid.z)), 0, int(_385.fa_cl_info.y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * _385.fa_cl_grid.y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * _385.fa_cl_grid.x)), 0, _462 - 1);\n    float4 _537 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_537.x), int(_537.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_385.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1440 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _385);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1541 = fa_linear_to_srgb(param);\n        c = _1541;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1549 = fa_srgb_to_linear(param_1);\n            c = _1549;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _157;\n    if (bool(i.front_facing))\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    float3 _181 = fast::normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    float3 _209 = fast::normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    float3 _212;\n    if (bool(i.front_facing))\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _385, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _385.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1580 = fa_tex_fix(param_2, param_3);\n    float4 _2374 = base_t;\n    _2374.x = _1580.x;\n    _2374.y = _1580.y;\n    _2374.z = _1580.z;\n    base_t = _2374;\n    float4 _1594 = (_2374 * _385.fa_base_color) * i.vertex_color;\n    float3 _2333 = i.world_normal;\n    if (_385.fa_maps.z > 0.5)\n    {\n        float param_4 = _385.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1626 = fa_tex_fix(param_6, param_7);\n        float3 _1630 = (_1626 * 2.0) - float3(1.0);\n        float2 _1635 = _1630.xy * _385.fa_maps.x;\n        float3 _2382 = _1630;\n        _2382.x = _1635.x;\n        _2382.y = _1635.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2382;\n        _2333 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _385.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1664 = fa_tex_fix(param_12, param_13);\n    float4 _2385 = mrt;\n    _2385.x = _1664.x;\n    _2385.y = _1664.y;\n    _2385.z = _1664.z;\n    mrt = _2385;\n    float param_14 = _385.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1703 = fa_tex_fix(param_16, param_17);\n    float param_18 = _385.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1730 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1594.xyz, _1594.w, _2333, fast::clamp(_385.fa_pbr.x * _1664.z, 0.0, 1.0), fast::clamp(_385.fa_pbr.y * _1664.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_385.fa_maps.y * (_1703.x - 1.0)), _385.fa_emissive.xyz + (_385.fa_model_emissive.xyz * _1730) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _385, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _385.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    int param = (int(_385.fa_cl_info.x) + int(_385.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _385);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _257 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _263 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    float3 l;\n    if (_273)\n    {\n        l = fast::normalize(_257.xyz);\n    }\n    else\n    {\n        float3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / float3(fast::max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / fast::max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = fast::clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _322 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            float4 _339 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, fast::normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _263.xyz * atten, atten, 1.0, dist, _371 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _621)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = _621.fa_shadow_split.x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = _621.fa_shadow_split.y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = _621.fa_shadow_split.z;\n            }\n            else\n            {\n                _635 = _621.fa_shadow_split.w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    float _673 = fast::max(_621.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _678 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = fast::min(_684 / fast::max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (_621.fa_shadow_bias.y > 0.0)\n    {\n        _697 = _621.fa_shadow_bias.y;\n    }\n    else\n    {\n        _697 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float4 _722 = _621.fa_shadow_mat[ci] * float4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < _621.fa_shadow_rect[ci].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > _621.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < _621.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > _621.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (_621.fa_shadow_bias.x > 0.0)\n    {\n        _775 = _621.fa_shadow_bias.x;\n    }\n    else\n    {\n        _775 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((_621.fa_shadow_info[ci].x * fast::min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(_621.fa_shadow_cfg.z + 0.5);\n    if (_812 == 1)\n    {\n        float2 param = _722.xy;\n        float4 param_1 = _621.fa_shadow_rect[ci];\n        float _823 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = fast::clamp(((_621.fa_shadow_cfg.w * _673) * 0.25) / _621.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            float2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            float2 param_5 = _722.xy + (_866 * _621.fa_shadow_bias.zw);\n            float4 param_6 = _621.fa_shadow_rect[ci];\n            float _877 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_794 - (sum / cnt), 0.0) * _673) * _621.fa_shadow_cfg.w) / _621.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        float2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _722.xy + (_940 * _621.fa_shadow_bias.zw);\n        float4 param_11 = _621.fa_shadow_rect[ci];\n        float _951 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    if (_385.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(_621.fa_shadow_cfg.x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param, _621))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > _621.fa_shadow_split.x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > _621.fa_shadow_split.y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > _621.fa_shadow_split.z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_621.fa_shadow_cfg.y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5, _621);\n        }\n        else\n        {\n            _1089 = _621.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1108 = _621.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _621) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = fast::clamp((_997 - (fa_shadow_split_at(param_7, _621) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2318 = _1468.direction;\n    float3 _2313 = _1468.color;\n    float _2315 = _1468.shadow;\n    int _2323 = _1468.type;\n    if ((_2323 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2318;\n        float _1482 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, fa_world_pos);\n        _2315 = _1482;\n        _2313 *= _1482;\n    }\n    return LightSample{ _2318, _2313, _1468.attenuation, _2315, _1468._distance, _2323 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1372 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _385.fa_env_horizon.w)).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(_385.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_385.fa_env_horizon.xyz, _385.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((_385.fa_env_sky.xyz + _385.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1277 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1414 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _385, fa_env_tex, fa_env_smp) * ((f0 * _1414.x) + float3(_1414.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _621)\n{\n    if (_621.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(_621.fa_shadow_cfg.x + 0.5);\n    float _1174 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param, _621);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > _621.fa_shadow_split.x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > _621.fa_shadow_split.y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > _621.fa_shadow_split.z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _385 [[buffer(1)]], constant fa_shadows& _621 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2238 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2238 = -_2238;\n    }\n    float3 _1773 = fast::normalize(_385.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2238, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1773, short(gl_FrontFacing) };\n    Surface _1781 = fa_standard_surface(param_1, _385, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2261 = _1781.albedo;\n    float _2262 = _1781.alpha;\n    float3 _2263 = _1781.normal;\n    float _2264 = _1781.metallic;\n    float _2265 = _1781.roughness;\n    float _2266 = _1781.occlusion;\n    float3 _2267 = _1781.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2238, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1773, short(gl_FrontFacing) };\n    Surface param_3 = _1781;\n    surface(param_2, param_3);\n    _2261 = param_3.albedo;\n    _2262 = param_3.alpha;\n    _2263 = param_3.normal;\n    _2264 = param_3.metallic;\n    _2265 = param_3.roughness;\n    _2266 = param_3.occlusion;\n    _2267 = param_3.emission;\n    float3 result;\n    if (_385.fa_emissive.w > 0.5)\n    {\n        result = _2261;\n    }\n    else\n    {\n        float3 _1803 = fast::normalize(_2263);\n        float _1810 = fast::clamp(_2264, 0.0, 1.0);\n        float _1814 = fast::clamp(_2265, 0.0500000007450580596923828125, 1.0);\n        float _1818 = _1814 * _1814;\n        float _1822 = _1818 * _1818;\n        float _1827 = fast::max(dot(_1803, _1773), 9.9999997473787516355514526367188e-05);\n        float3 _1833 = _2261 * (1.0 - _1810);\n        float3 _1841 = mix(float3(0.039999999105930328369140625), _2261, float3(_1810));\n        float3 param_4 = _1803;\n        float3 lit = (fa_ambient_light(param_4, _385, fa_env_smp, fa_irr_tex) * _1833) * _2266;\n        int _1854 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1854; ln++)\n        {\n            int param_5 = ln;\n            int _1867 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1867;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2238;\n            LightSample _1876 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, in.fa_world_pos);\n            float3 _2296 = _1876.direction;\n            float _1884 = fast::max(dot(_1803, _2296), 0.0);\n            float3 _1895 = fast::normalize(_2296 + _1773);\n            float _1900 = fast::max(dot(_1803, _1895), 0.0);\n            float _1913 = ((_1900 * _1900) * (_1822 - 1.0)) + 1.0;\n            int param_9 = _1867;\n            lit += (((_1833 + (((_1841 + ((float3(1.0) - _1841) * powr(1.0 - fast::max(dot(_1773, _1895), 0.0), 5.0))) * (((_1822 / ((3.1415927410125732421875 * _1913) * _1913)) * (0.5 / fast::max(mix((2.0 * _1884) * _1827, _1884 + _1827, _1818), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1884))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1884 * (_1876.attenuation * _1876.shadow)));\n        }\n        float3 param_10 = _1803;\n        float3 param_11 = _1773;\n        float3 param_12 = _1841;\n        float param_13 = _1814;\n        float3 _1982 = lit;\n        float3 _1983 = _1982 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _385, fa_env_tex, fa_env_smp) * _2266);\n        lit = _1983;\n        result = _1983;\n    }\n    float3 _1987 = result;\n    float3 _1988 = _1987 + _2267;\n    result = _1988;\n    float3 param_14 = _1988;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _621);\n    bool _1997 = _385.fa_fog.w > 0.0;\n    bool _2005;\n    if (!_1997)\n    {\n        _2005 = _385.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2005 = _1997;\n    }\n    if (_2005)\n    {\n        float3 _2014 = in.fa_world_pos - _385.fa_camera_pos.xyz;\n        float _2021 = dot(_2014, _385.fa_fog_c.xyz);\n        bool _2025 = _385.fa_fog_c.w > 0.5;\n        float _2026;\n        if (_2025)\n        {\n            _2026 = _2021;\n        }\n        else\n        {\n            _2026 = length(_2014);\n        }\n        float _2038 = _2026 - _385.fa_fog_b.x;\n        if (_2038 > 0.0)\n        {\n            float _2047 = _385.fa_fog.w * _2038;\n            float tau = _2047 * _2047;\n            if (_385.fa_fog_b.y > 0.0)\n            {\n                float _2063;\n                if (_2025)\n                {\n                    _2063 = in.fa_world_pos.y - (_385.fa_fog_c.y * _2021);\n                }\n                else\n                {\n                    _2063 = _385.fa_camera_pos.y;\n                }\n                float _2084 = mix(_2063, in.fa_world_pos.y, fast::clamp(_385.fa_fog_b.x / _2026, 0.0, 1.0));\n                float _2088 = in.fa_world_pos.y - _2084;\n                float _2093 = _2084 - _385.fa_fog_b.z;\n                float _2098 = in.fa_world_pos.y - _385.fa_fog_b.z;\n                bool _2101 = _2093 <= 0.0;\n                bool _2102 = !_2101;\n                bool _2108;\n                if (_2102)\n                {\n                    _2108 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2108 = _2101;\n                }\n                float _2109;\n                if (_2108)\n                {\n                    _2109 = _385.fa_fog_b.y;\n                }\n                else\n                {\n                    _2109 = _385.fa_fog_b.y * exp(-fast::min(_385.fa_fog_b.w * _2093, 80.0));\n                }\n                bool _2136;\n                if (_2102)\n                {\n                    _2136 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2136 = _2101;\n                }\n                float _2137;\n                if (_2136)\n                {\n                    _2137 = _385.fa_fog_b.y * _2093;\n                }\n                else\n                {\n                    _2137 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2093, 80.0)))) / _385.fa_fog_b.w;\n                }\n                bool _2162 = _2098 <= 0.0;\n                bool _2169;\n                if (!_2162)\n                {\n                    _2169 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2169 = _2162;\n                }\n                float _2170;\n                if (_2169)\n                {\n                    _2170 = _385.fa_fog_b.y * _2098;\n                }\n                else\n                {\n                    _2170 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2098, 80.0)))) / _385.fa_fog_b.w;\n                }\n                float _2197;\n                if (abs(_2088) < 0.001000000047497451305389404296875)\n                {\n                    _2197 = _2109;\n                }\n                else\n                {\n                    _2197 = (_2170 - _2137) / _2088;\n                }\n                tau += (_2038 * fast::max(_2197, 0.0));\n            }\n            result = mix(result, _385.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2262);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    bool _390 = _385.fa_cl_info.x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = _385.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = _385.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = _385.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = _385.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return int2(0);\n    }\n    float4 _429 = float4(world_pos, 1.0);\n    float _436 = dot(_385.fa_cl_vpw, _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _458 = float2(dot(_385.fa_cl_vpx, _429), dot(_385.fa_cl_vpy, _429)) / float2(_436);\n    int _462 = int(_385.fa_cl_grid.x);\n    int _466 = int(_385.fa_cl_grid.y);\n    int param = (int(_385.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_385.fa_cl_fwd.xyz, world_pos) + _385.fa_cl_fwd.w, _385.fa_cl_grid.w) / _385.fa_cl_grid.w) * _385.fa_cl_grid.z)), 0, int(_385.fa_cl_info.y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * _385.fa_cl_grid.y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * _385.fa_cl_grid.x)), 0, _462 - 1);\n    float4 _537 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_537.x), int(_537.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_385.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1440 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _385);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1541 = fa_linear_to_srgb(param);\n        c = _1541;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1549 = fa_srgb_to_linear(param_1);\n            c = _1549;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _157;\n    if (bool(i.front_facing))\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    float3 _181 = fast::normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    float3 _209 = fast::normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    float3 _212;\n    if (bool(i.front_facing))\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _385, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _385.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1580 = fa_tex_fix(param_2, param_3);\n    float4 _2374 = base_t;\n    _2374.x = _1580.x;\n    _2374.y = _1580.y;\n    _2374.z = _1580.z;\n    base_t = _2374;\n    float4 _1594 = (_2374 * _385.fa_base_color) * i.vertex_color;\n    float3 _2333 = i.world_normal;\n    if (_385.fa_maps.z > 0.5)\n    {\n        float param_4 = _385.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1626 = fa_tex_fix(param_6, param_7);\n        float3 _1630 = (_1626 * 2.0) - float3(1.0);\n        float2 _1635 = _1630.xy * _385.fa_maps.x;\n        float3 _2382 = _1630;\n        _2382.x = _1635.x;\n        _2382.y = _1635.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2382;\n        _2333 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _385.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1664 = fa_tex_fix(param_12, param_13);\n    float4 _2385 = mrt;\n    _2385.x = _1664.x;\n    _2385.y = _1664.y;\n    _2385.z = _1664.z;\n    mrt = _2385;\n    float param_14 = _385.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1703 = fa_tex_fix(param_16, param_17);\n    float param_18 = _385.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1730 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1594.xyz, _1594.w, _2333, fast::clamp(_385.fa_pbr.x * _1664.z, 0.0, 1.0), fast::clamp(_385.fa_pbr.y * _1664.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_385.fa_maps.y * (_1703.x - 1.0)), _385.fa_emissive.xyz + (_385.fa_model_emissive.xyz * _1730) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _385, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _385.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385)\n{\n    int param = (int(_385.fa_cl_info.x) + int(_385.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _385);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _257 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _263 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    float3 l;\n    if (_273)\n    {\n        l = fast::normalize(_257.xyz);\n    }\n    else\n    {\n        float3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / float3(fast::max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / fast::max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = fast::clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _322 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            float4 _339 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, fast::normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _263.xyz * atten, atten, 1.0, dist, _371 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _621)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = _621.fa_shadow_split.x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = _621.fa_shadow_split.y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = _621.fa_shadow_split.z;\n            }\n            else\n            {\n                _635 = _621.fa_shadow_split.w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    float _673 = fast::max(_621.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _678 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = fast::min(_684 / fast::max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (_621.fa_shadow_bias.y > 0.0)\n    {\n        _697 = _621.fa_shadow_bias.y;\n    }\n    else\n    {\n        _697 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float4 _722 = _621.fa_shadow_mat[ci] * float4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < _621.fa_shadow_rect[ci].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > _621.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < _621.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > _621.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (_621.fa_shadow_bias.x > 0.0)\n    {\n        _775 = _621.fa_shadow_bias.x;\n    }\n    else\n    {\n        _775 = 1.5 * _621.fa_shadow_info[ci].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((_621.fa_shadow_info[ci].x * fast::min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(_621.fa_shadow_cfg.z + 0.5);\n    if (_812 == 1)\n    {\n        float2 param = _722.xy;\n        float4 param_1 = _621.fa_shadow_rect[ci];\n        float _823 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = fast::clamp(((_621.fa_shadow_cfg.w * _673) * 0.25) / _621.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            float2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            float2 param_5 = _722.xy + (_866 * _621.fa_shadow_bias.zw);\n            float4 param_6 = _621.fa_shadow_rect[ci];\n            float _877 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_794 - (sum / cnt), 0.0) * _673) * _621.fa_shadow_cfg.w) / _621.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        float2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _722.xy + (_940 * _621.fa_shadow_bias.zw);\n        float4 param_11 = _621.fa_shadow_rect[ci];\n        float _951 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex)\n{\n    if (_385.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(_621.fa_shadow_cfg.x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param, _621))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > _621.fa_shadow_split.x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > _621.fa_shadow_split.y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > _621.fa_shadow_split.z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_621.fa_shadow_cfg.y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5, _621);\n        }\n        else\n        {\n            _1089 = _621.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1108 = _621.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _621) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = fast::clamp((_997 - (fa_shadow_split_at(param_7, _621) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _621, fa_shadow_tex);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _385, thread float4& gl_FragCoord, constant fa_shadows& _621, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2318 = _1468.direction;\n    float3 _2313 = _1468.color;\n    float _2315 = _1468.shadow;\n    int _2323 = _1468.type;\n    if ((_2323 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2318;\n        float _1482 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, fa_world_pos);\n        _2315 = _1482;\n        _2313 *= _1482;\n    }\n    return LightSample{ _2318, _2313, _1468.attenuation, _2315, _1468._distance, _2323 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1372 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_385.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _385.fa_env_horizon.w)).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(_385.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_385.fa_env_horizon.xyz, _385.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((_385.fa_env_sky.xyz + _385.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1277 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _385, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1414 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _385, fa_env_tex, fa_env_smp) * ((f0 * _1414.x) + float3(_1414.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _621)\n{\n    if (_621.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(_621.fa_shadow_cfg.x + 0.5);\n    float _1174 = dot(world - _621.fa_shadow_eye.xyz, _621.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param, _621);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > _621.fa_shadow_split.x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > _621.fa_shadow_split.y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > _621.fa_shadow_split.z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _385 [[buffer(1)]], constant fa_shadows& _621 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2238 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2238 = -_2238;\n    }\n    float3 _1773 = fast::normalize(_385.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2238, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1773, short(gl_FrontFacing) };\n    Surface _1781 = fa_standard_surface(param_1, _385, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2261 = _1781.albedo;\n    float _2262 = _1781.alpha;\n    float3 _2263 = _1781.normal;\n    float _2264 = _1781.metallic;\n    float _2265 = _1781.roughness;\n    float _2266 = _1781.occlusion;\n    float3 _2267 = _1781.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2238, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1773, short(gl_FrontFacing) };\n    Surface param_3 = _1781;\n    surface(param_2, param_3);\n    _2261 = param_3.albedo;\n    _2262 = param_3.alpha;\n    _2263 = param_3.normal;\n    _2264 = param_3.metallic;\n    _2265 = param_3.roughness;\n    _2266 = param_3.occlusion;\n    _2267 = param_3.emission;\n    float3 result;\n    if (_385.fa_emissive.w > 0.5)\n    {\n        result = _2261;\n    }\n    else\n    {\n        float3 _1803 = fast::normalize(_2263);\n        float _1810 = fast::clamp(_2264, 0.0, 1.0);\n        float _1814 = fast::clamp(_2265, 0.0500000007450580596923828125, 1.0);\n        float _1818 = _1814 * _1814;\n        float _1822 = _1818 * _1818;\n        float _1827 = fast::max(dot(_1803, _1773), 9.9999997473787516355514526367188e-05);\n        float3 _1833 = _2261 * (1.0 - _1810);\n        float3 _1841 = mix(float3(0.039999999105930328369140625), _2261, float3(_1810));\n        float3 param_4 = _1803;\n        float3 lit = (fa_ambient_light(param_4, _385, fa_env_smp, fa_irr_tex) * _1833) * _2266;\n        int _1854 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1854; ln++)\n        {\n            int param_5 = ln;\n            int _1867 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _385, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1867;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2238;\n            LightSample _1876 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _385, gl_FragCoord, _621, fa_shadow_tex, in.fa_world_pos);\n            float3 _2296 = _1876.direction;\n            float _1884 = fast::max(dot(_1803, _2296), 0.0);\n            float3 _1895 = fast::normalize(_2296 + _1773);\n            float _1900 = fast::max(dot(_1803, _1895), 0.0);\n            float _1913 = ((_1900 * _1900) * (_1822 - 1.0)) + 1.0;\n            int param_9 = _1867;\n            lit += (((_1833 + (((_1841 + ((float3(1.0) - _1841) * powr(1.0 - fast::max(dot(_1773, _1895), 0.0), 5.0))) * (((_1822 / ((3.1415927410125732421875 * _1913) * _1913)) * (0.5 / fast::max(mix((2.0 * _1884) * _1827, _1884 + _1827, _1818), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1884))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1884 * (_1876.attenuation * _1876.shadow)));\n        }\n        float3 param_10 = _1803;\n        float3 param_11 = _1773;\n        float3 param_12 = _1841;\n        float param_13 = _1814;\n        float3 _1982 = lit;\n        float3 _1983 = _1982 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _385, fa_env_tex, fa_env_smp) * _2266);\n        lit = _1983;\n        result = _1983;\n    }\n    float3 _1987 = result;\n    float3 _1988 = _1987 + _2267;\n    result = _1988;\n    float3 param_14 = _1988;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _621);\n    bool _1997 = _385.fa_fog.w > 0.0;\n    bool _2005;\n    if (!_1997)\n    {\n        _2005 = _385.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2005 = _1997;\n    }\n    if (_2005)\n    {\n        float3 _2014 = in.fa_world_pos - _385.fa_camera_pos.xyz;\n        float _2021 = dot(_2014, _385.fa_fog_c.xyz);\n        bool _2025 = _385.fa_fog_c.w > 0.5;\n        float _2026;\n        if (_2025)\n        {\n            _2026 = _2021;\n        }\n        else\n        {\n            _2026 = length(_2014);\n        }\n        float _2038 = _2026 - _385.fa_fog_b.x;\n        if (_2038 > 0.0)\n        {\n            float _2047 = _385.fa_fog.w * _2038;\n            float tau = _2047 * _2047;\n            if (_385.fa_fog_b.y > 0.0)\n            {\n                float _2063;\n                if (_2025)\n                {\n                    _2063 = in.fa_world_pos.y - (_385.fa_fog_c.y * _2021);\n                }\n                else\n                {\n                    _2063 = _385.fa_camera_pos.y;\n                }\n                float _2084 = mix(_2063, in.fa_world_pos.y, fast::clamp(_385.fa_fog_b.x / _2026, 0.0, 1.0));\n                float _2088 = in.fa_world_pos.y - _2084;\n                float _2093 = _2084 - _385.fa_fog_b.z;\n                float _2098 = in.fa_world_pos.y - _385.fa_fog_b.z;\n                bool _2101 = _2093 <= 0.0;\n                bool _2102 = !_2101;\n                bool _2108;\n                if (_2102)\n                {\n                    _2108 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2108 = _2101;\n                }\n                float _2109;\n                if (_2108)\n                {\n                    _2109 = _385.fa_fog_b.y;\n                }\n                else\n                {\n                    _2109 = _385.fa_fog_b.y * exp(-fast::min(_385.fa_fog_b.w * _2093, 80.0));\n                }\n                bool _2136;\n                if (_2102)\n                {\n                    _2136 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2136 = _2101;\n                }\n                float _2137;\n                if (_2136)\n                {\n                    _2137 = _385.fa_fog_b.y * _2093;\n                }\n                else\n                {\n                    _2137 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2093, 80.0)))) / _385.fa_fog_b.w;\n                }\n                bool _2162 = _2098 <= 0.0;\n                bool _2169;\n                if (!_2162)\n                {\n                    _2169 = _385.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2169 = _2162;\n                }\n                float _2170;\n                if (_2169)\n                {\n                    _2170 = _385.fa_fog_b.y * _2098;\n                }\n                else\n                {\n                    _2170 = (_385.fa_fog_b.y * (1.0 - exp(-fast::min(_385.fa_fog_b.w * _2098, 80.0)))) / _385.fa_fog_b.w;\n                }\n                float _2197;\n                if (abs(_2088) < 0.001000000047497451305389404296875)\n                {\n                    _2197 = _2109;\n                }\n                else\n                {\n                    _2197 = (_2170 - _2137) / _2088;\n                }\n                tau += (_2038 * fast::max(_2197, 0.0));\n            }\n            result = mix(result, _385.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2262);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213.fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _568, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _515 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213.fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _568, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _515 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _515, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
