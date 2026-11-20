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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363)\n{\n    bool _368 = _363.fa_cl_info.x < 0.0;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0);\n    }\n    float4 _407 = float4(world_pos, 1.0);\n    float _414 = dot(_363.fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _436 = float2(dot(_363.fa_cl_vpx, _407), dot(_363.fa_cl_vpy, _407)) / float2(_414);\n    int _440 = int(_363.fa_cl_grid.x);\n    int _444 = int(_363.fa_cl_grid.y);\n    int param = (int(_363.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_363.fa_cl_fwd.xyz, world_pos) + _363.fa_cl_fwd.w, _363.fa_cl_grid.w) / _363.fa_cl_grid.w) * _363.fa_cl_grid.z)), 0, int(_363.fa_cl_info.y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5) + 0.5) * _363.fa_cl_grid.y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5) + 0.5) * _363.fa_cl_grid.x)), 0, _440 - 1);\n    float4 _515 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_515.x), int(_515.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_363.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1260 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _363);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1363 = fa_linear_to_srgb(param);\n        c = _1363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1371 = fa_srgb_to_linear(param_1);\n            c = _1371;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _144;\n    if (bool(i.front_facing))\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    float3 _168 = fast::normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    float3 _196 = fast::normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    float3 _199;\n    if (bool(i.front_facing))\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _363, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _363.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1402 = fa_tex_fix(param_2, param_3);\n    float4 _2091 = base_t;\n    _2091.x = _1402.x;\n    _2091.y = _1402.y;\n    _2091.z = _1402.z;\n    base_t = _2091;\n    float4 _1416 = (_2091 * _363.fa_base_color) * i.vertex_color;\n    float3 _2056 = i.world_normal;\n    if (_363.fa_maps.z > 0.5)\n    {\n        float param_4 = _363.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1448 = fa_tex_fix(param_6, param_7);\n        float3 _1452 = (_1448 * 2.0) - float3(1.0);\n        float2 _1457 = _1452.xy * _363.fa_maps.x;\n        float3 _2099 = _1452;\n        _2099.x = _1457.x;\n        _2099.y = _1457.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2099;\n        _2056 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _363.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1486 = fa_tex_fix(param_12, param_13);\n    float4 _2102 = mrt;\n    _2102.x = _1486.x;\n    _2102.y = _1486.y;\n    _2102.z = _1486.z;\n    mrt = _2102;\n    float param_14 = _363.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1526 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1553 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1416.xyz, _1416.w, _2056, fast::clamp(_363.fa_pbr.x * _1486.z, 0.0, 1.0), fast::clamp(_363.fa_pbr.y * _1486.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_363.fa_maps.y * (_1526.x - 1.0)), _363.fa_emissive.xyz + (_363.fa_model_emissive.xyz * _1553) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _363, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_363.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _363.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363)\n{\n    int param = (int(_363.fa_cl_info.x) + int(_363.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _363);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _236 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _242 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _245 = _242.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _252 = _245 < 0.5;\n    float3 l;\n    if (_252)\n    {\n        l = fast::normalize(_236.xyz);\n    }\n    else\n    {\n        float3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / float3(fast::max(_266, 9.9999997473787516355514526367188e-05));\n        float _281 = _266 / fast::max(_236.w, 0.001000000047497451305389404296875);\n        float _287 = fast::clamp(1.0 - (_281 * _281), 0.0, 1.0);\n        atten = _287 * _287;\n        if (_245 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _301 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            float4 _318 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5)\n            {\n                cos_inner = mix(_311, 1.0, 0.25);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, fast::normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _242.xyz * atten, atten, 1.0, dist, _349 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _599)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = _599.fa_shadow_split.x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = _599.fa_shadow_split.y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = _599.fa_shadow_split.z;\n            }\n            else\n            {\n                _613 = _599.fa_shadow_split.w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex)\n{\n    float _651 = fast::max(_599.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _656 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _662 = sqrt(1.0 - (_656 * _656));\n    float _670 = fast::min(_662 / fast::max(_656, 0.20000000298023223876953125), 4.0);\n    float _675;\n    if (_599.fa_shadow_bias.y > 0.0)\n    {\n        _675 = _599.fa_shadow_bias.y;\n    }\n    else\n    {\n        _675 = 1.5 * _599.fa_shadow_info[ci].x;\n    }\n    float4 _700 = _599.fa_shadow_mat[ci] * float4(world + (n * (_675 * _662)), 1.0);\n    float _707 = _700.x;\n    bool _710 = _707 < _599.fa_shadow_rect[ci].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > _599.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < _599.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > _599.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0;\n    }\n    float _753;\n    if (_599.fa_shadow_bias.x > 0.0)\n    {\n        _753 = _599.fa_shadow_bias.x;\n    }\n    else\n    {\n        _753 = 1.5 * _599.fa_shadow_info[ci].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0 + (0.5 * _670))) / _651);\n    float _781 = ((_599.fa_shadow_info[ci].x * fast::min(_670, 3.0)) * 0.5) / _651;\n    int _790 = int(_599.fa_shadow_cfg.z + 0.5);\n    if (_790 == 1)\n    {\n        float2 param = _700.xy;\n        float4 param_1 = _599.fa_shadow_rect[ci];\n        float _801 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = fast::clamp(((_599.fa_shadow_cfg.w * _651) * 0.25) / _599.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            float2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            float2 param_5 = _700.xy + (_844 * _599.fa_shadow_bias.zw);\n            float4 param_6 = _599.fa_shadow_rect[ci];\n            float _855 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_772 - (sum / cnt), 0.0) * _651) * _599.fa_shadow_cfg.w) / _599.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        float2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _700.xy + (_918 * _599.fa_shadow_bias.zw);\n        float4 param_11 = _599.fa_shadow_rect[ci];\n        float _929 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex)\n{\n    if (_363.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _959 = int(_599.fa_shadow_cfg.x + 0.5);\n    if (_959 < 1)\n    {\n        return 1.0;\n    }\n    float _975 = dot(world - _599.fa_shadow_eye.xyz, _599.fa_shadow_fwd.xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param, _599))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > _599.fa_shadow_split.x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > _599.fa_shadow_split.y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > _599.fa_shadow_split.z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _599, fa_shadow_tex);\n        s = _1042;\n        if (_1042 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_599.fa_shadow_cfg.y > 0.0)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5, _599);\n        }\n        else\n        {\n            _1067 = _599.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1086 = _599.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _599) - _1067, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1097 = fast::clamp((_975 - (fa_shadow_split_at(param_7, _599) - _1086)) / _1086, 0.0, 1.0);\n        if (_1097 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _599, fa_shadow_tex);\n                s2 = _1118;\n                if (_1118 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2041 = _1288.direction;\n    float3 _2036 = _1288.color;\n    float _2038 = _1288.shadow;\n    int _2046 = _1288.type;\n    if ((_2046 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2041;\n        float _1302 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex, fa_world_pos);\n        _2038 = _1302;\n        _2036 *= _1302;\n    }\n    return LightSample{ _2041, _2036, _1288.attenuation, _2038, _1288._distance, _2046 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _599)\n{\n    if (_599.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1142 = int(_599.fa_shadow_cfg.x + 0.5);\n    float _1152 = dot(world - _599.fa_shadow_eye.xyz, _599.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param, _599);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > _599.fa_shadow_split.x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > _599.fa_shadow_split.y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > _599.fa_shadow_split.z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _363 [[buffer(1)]], constant fa_shadows& _599 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1935 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _1935 = -_1935;\n    }\n    float3 _1596 = fast::normalize(_363.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _363, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n    Surface _1604 = fa_standard_surface(param_1, _363, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1966 = _1604.albedo;\n    float _1967 = _1604.alpha;\n    float3 _1968 = _1604.normal;\n    float _1969 = _1604.metallic;\n    float _1970 = _1604.roughness;\n    float _1971 = _1604.occlusion;\n    float3 _1972 = _1604.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n    Surface param_3 = _1604;\n    surface(param_2, param_3);\n    _1966 = param_3.albedo;\n    _1967 = param_3.alpha;\n    _1968 = param_3.normal;\n    _1969 = param_3.metallic;\n    _1970 = param_3.roughness;\n    _1971 = param_3.occlusion;\n    _1972 = param_3.emission;\n    float3 result;\n    if (_363.fa_emissive.w > 0.5)\n    {\n        result = _1966;\n    }\n    else\n    {\n        float3 _1625 = _1968;\n        float3 _1626 = fast::normalize(_1625);\n        _1968 = _1626;\n        float3 param_4 = _1626;\n        float3 lit = (fa_ambient_light(param_4, _363, fa_irr_tex, fa_env_smp) * _1966) * _1971;\n        int _1645 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1645; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _363, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _1935;\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _1966, _1967, _1968, _1969, _1970, _1971, _1972 };\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _1682 = result;\n    float3 _1683 = _1682 + _1972;\n    result = _1683;\n    float3 param_12 = _1683;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _599);\n    bool _1692 = _363.fa_fog.w > 0.0;\n    bool _1700;\n    if (!_1692)\n    {\n        _1700 = _363.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1700 = _1692;\n    }\n    if (_1700)\n    {\n        float3 _1709 = in.fa_world_pos - _363.fa_camera_pos.xyz;\n        float _1716 = dot(_1709, _363.fa_fog_c.xyz);\n        bool _1720 = _363.fa_fog_c.w > 0.5;\n        float _1721;\n        if (_1720)\n        {\n            _1721 = _1716;\n        }\n        else\n        {\n            _1721 = length(_1709);\n        }\n        float _1733 = _1721 - _363.fa_fog_b.x;\n        if (_1733 > 0.0)\n        {\n            float _1742 = _363.fa_fog.w * _1733;\n            float tau = _1742 * _1742;\n            if (_363.fa_fog_b.y > 0.0)\n            {\n                float _1758;\n                if (_1720)\n                {\n                    _1758 = in.fa_world_pos.y - (_363.fa_fog_c.y * _1716);\n                }\n                else\n                {\n                    _1758 = _363.fa_camera_pos.y;\n                }\n                float _1779 = mix(_1758, in.fa_world_pos.y, fast::clamp(_363.fa_fog_b.x / _1721, 0.0, 1.0));\n                float _1783 = in.fa_world_pos.y - _1779;\n                float _1788 = _1779 - _363.fa_fog_b.z;\n                float _1793 = in.fa_world_pos.y - _363.fa_fog_b.z;\n                bool _1796 = _1788 <= 0.0;\n                bool _1797 = !_1796;\n                bool _1803;\n                if (_1797)\n                {\n                    _1803 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1803 = _1796;\n                }\n                float _1804;\n                if (_1803)\n                {\n                    _1804 = _363.fa_fog_b.y;\n                }\n                else\n                {\n                    _1804 = _363.fa_fog_b.y * exp(-fast::min(_363.fa_fog_b.w * _1788, 80.0));\n                }\n                bool _1831;\n                if (_1797)\n                {\n                    _1831 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1831 = _1796;\n                }\n                float _1832;\n                if (_1831)\n                {\n                    _1832 = _363.fa_fog_b.y * _1788;\n                }\n                else\n                {\n                    _1832 = (_363.fa_fog_b.y * (1.0 - exp(-fast::min(_363.fa_fog_b.w * _1788, 80.0)))) / _363.fa_fog_b.w;\n                }\n                bool _1857 = _1793 <= 0.0;\n                bool _1864;\n                if (!_1857)\n                {\n                    _1864 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1864 = _1857;\n                }\n                float _1865;\n                if (_1864)\n                {\n                    _1865 = _363.fa_fog_b.y * _1793;\n                }\n                else\n                {\n                    _1865 = (_363.fa_fog_b.y * (1.0 - exp(-fast::min(_363.fa_fog_b.w * _1793, 80.0)))) / _363.fa_fog_b.w;\n                }\n                float _1892;\n                if (abs(_1783) < 0.001000000047497451305389404296875)\n                {\n                    _1892 = _1804;\n                }\n                else\n                {\n                    _1892 = (_1865 - _1832) / _1783;\n                }\n                tau += (_1733 * fast::max(_1892, 0.0));\n            }\n            result = mix(result, _363.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1967);\n    return out;\n}\n\n",
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
            "inst_name": "_363",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363)\n{\n    bool _368 = _363.fa_cl_info.x < 0.0;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0);\n    }\n    float4 _407 = float4(world_pos, 1.0);\n    float _414 = dot(_363.fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _436 = float2(dot(_363.fa_cl_vpx, _407), dot(_363.fa_cl_vpy, _407)) / float2(_414);\n    int _440 = int(_363.fa_cl_grid.x);\n    int _444 = int(_363.fa_cl_grid.y);\n    int param = (int(_363.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_363.fa_cl_fwd.xyz, world_pos) + _363.fa_cl_fwd.w, _363.fa_cl_grid.w) / _363.fa_cl_grid.w) * _363.fa_cl_grid.z)), 0, int(_363.fa_cl_info.y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5) + 0.5) * _363.fa_cl_grid.y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5) + 0.5) * _363.fa_cl_grid.x)), 0, _440 - 1);\n    float4 _515 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_515.x), int(_515.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_363.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1260 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _363);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1363 = fa_linear_to_srgb(param);\n        c = _1363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1371 = fa_srgb_to_linear(param_1);\n            c = _1371;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _144;\n    if (bool(i.front_facing))\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    float3 _168 = fast::normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    float3 _196 = fast::normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    float3 _199;\n    if (bool(i.front_facing))\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _363, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _363.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1402 = fa_tex_fix(param_2, param_3);\n    float4 _2091 = base_t;\n    _2091.x = _1402.x;\n    _2091.y = _1402.y;\n    _2091.z = _1402.z;\n    base_t = _2091;\n    float4 _1416 = (_2091 * _363.fa_base_color) * i.vertex_color;\n    float3 _2056 = i.world_normal;\n    if (_363.fa_maps.z > 0.5)\n    {\n        float param_4 = _363.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1448 = fa_tex_fix(param_6, param_7);\n        float3 _1452 = (_1448 * 2.0) - float3(1.0);\n        float2 _1457 = _1452.xy * _363.fa_maps.x;\n        float3 _2099 = _1452;\n        _2099.x = _1457.x;\n        _2099.y = _1457.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2099;\n        _2056 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _363.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1486 = fa_tex_fix(param_12, param_13);\n    float4 _2102 = mrt;\n    _2102.x = _1486.x;\n    _2102.y = _1486.y;\n    _2102.z = _1486.z;\n    mrt = _2102;\n    float param_14 = _363.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1526 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1553 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1416.xyz, _1416.w, _2056, fast::clamp(_363.fa_pbr.x * _1486.z, 0.0, 1.0), fast::clamp(_363.fa_pbr.y * _1486.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_363.fa_maps.y * (_1526.x - 1.0)), _363.fa_emissive.xyz + (_363.fa_model_emissive.xyz * _1553) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _363, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_363.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _363.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363)\n{\n    int param = (int(_363.fa_cl_info.x) + int(_363.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _363);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _236 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _242 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _245 = _242.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _252 = _245 < 0.5;\n    float3 l;\n    if (_252)\n    {\n        l = fast::normalize(_236.xyz);\n    }\n    else\n    {\n        float3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / float3(fast::max(_266, 9.9999997473787516355514526367188e-05));\n        float _281 = _266 / fast::max(_236.w, 0.001000000047497451305389404296875);\n        float _287 = fast::clamp(1.0 - (_281 * _281), 0.0, 1.0);\n        atten = _287 * _287;\n        if (_245 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _301 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            float4 _318 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5)\n            {\n                cos_inner = mix(_311, 1.0, 0.25);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, fast::normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _242.xyz * atten, atten, 1.0, dist, _349 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _599)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = _599.fa_shadow_split.x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = _599.fa_shadow_split.y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = _599.fa_shadow_split.z;\n            }\n            else\n            {\n                _613 = _599.fa_shadow_split.w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex)\n{\n    float _651 = fast::max(_599.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _656 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _662 = sqrt(1.0 - (_656 * _656));\n    float _670 = fast::min(_662 / fast::max(_656, 0.20000000298023223876953125), 4.0);\n    float _675;\n    if (_599.fa_shadow_bias.y > 0.0)\n    {\n        _675 = _599.fa_shadow_bias.y;\n    }\n    else\n    {\n        _675 = 1.5 * _599.fa_shadow_info[ci].x;\n    }\n    float4 _700 = _599.fa_shadow_mat[ci] * float4(world + (n * (_675 * _662)), 1.0);\n    float _707 = _700.x;\n    bool _710 = _707 < _599.fa_shadow_rect[ci].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > _599.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < _599.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > _599.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0;\n    }\n    float _753;\n    if (_599.fa_shadow_bias.x > 0.0)\n    {\n        _753 = _599.fa_shadow_bias.x;\n    }\n    else\n    {\n        _753 = 1.5 * _599.fa_shadow_info[ci].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0 + (0.5 * _670))) / _651);\n    float _781 = ((_599.fa_shadow_info[ci].x * fast::min(_670, 3.0)) * 0.5) / _651;\n    int _790 = int(_599.fa_shadow_cfg.z + 0.5);\n    if (_790 == 1)\n    {\n        float2 param = _700.xy;\n        float4 param_1 = _599.fa_shadow_rect[ci];\n        float _801 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = fast::clamp(((_599.fa_shadow_cfg.w * _651) * 0.25) / _599.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            float2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            float2 param_5 = _700.xy + (_844 * _599.fa_shadow_bias.zw);\n            float4 param_6 = _599.fa_shadow_rect[ci];\n            float _855 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_772 - (sum / cnt), 0.0) * _651) * _599.fa_shadow_cfg.w) / _599.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        float2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _700.xy + (_918 * _599.fa_shadow_bias.zw);\n        float4 param_11 = _599.fa_shadow_rect[ci];\n        float _929 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex)\n{\n    if (_363.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _959 = int(_599.fa_shadow_cfg.x + 0.5);\n    if (_959 < 1)\n    {\n        return 1.0;\n    }\n    float _975 = dot(world - _599.fa_shadow_eye.xyz, _599.fa_shadow_fwd.xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param, _599))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > _599.fa_shadow_split.x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > _599.fa_shadow_split.y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > _599.fa_shadow_split.z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _599, fa_shadow_tex);\n        s = _1042;\n        if (_1042 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_599.fa_shadow_cfg.y > 0.0)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5, _599);\n        }\n        else\n        {\n            _1067 = _599.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1086 = _599.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _599) - _1067, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1097 = fast::clamp((_975 - (fa_shadow_split_at(param_7, _599) - _1086)) / _1086, 0.0, 1.0);\n        if (_1097 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _599, fa_shadow_tex);\n                s2 = _1118;\n                if (_1118 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _363, thread float4& gl_FragCoord, constant fa_shadows& _599, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2041 = _1288.direction;\n    float3 _2036 = _1288.color;\n    float _2038 = _1288.shadow;\n    int _2046 = _1288.type;\n    if ((_2046 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2041;\n        float _1302 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex, fa_world_pos);\n        _2038 = _1302;\n        _2036 *= _1302;\n    }\n    return LightSample{ _2041, _2036, _1288.attenuation, _2038, _1288._distance, _2046 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _599)\n{\n    if (_599.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1142 = int(_599.fa_shadow_cfg.x + 0.5);\n    float _1152 = dot(world - _599.fa_shadow_eye.xyz, _599.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param, _599);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > _599.fa_shadow_split.x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > _599.fa_shadow_split.y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > _599.fa_shadow_split.z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _363 [[buffer(1)]], constant fa_shadows& _599 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1935 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _1935 = -_1935;\n    }\n    float3 _1596 = fast::normalize(_363.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _363, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n    Surface _1604 = fa_standard_surface(param_1, _363, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1966 = _1604.albedo;\n    float _1967 = _1604.alpha;\n    float3 _1968 = _1604.normal;\n    float _1969 = _1604.metallic;\n    float _1970 = _1604.roughness;\n    float _1971 = _1604.occlusion;\n    float3 _1972 = _1604.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n    Surface param_3 = _1604;\n    surface(param_2, param_3);\n    _1966 = param_3.albedo;\n    _1967 = param_3.alpha;\n    _1968 = param_3.normal;\n    _1969 = param_3.metallic;\n    _1970 = param_3.roughness;\n    _1971 = param_3.occlusion;\n    _1972 = param_3.emission;\n    float3 result;\n    if (_363.fa_emissive.w > 0.5)\n    {\n        result = _1966;\n    }\n    else\n    {\n        float3 _1625 = _1968;\n        float3 _1626 = fast::normalize(_1625);\n        _1968 = _1626;\n        float3 param_4 = _1626;\n        float3 lit = (fa_ambient_light(param_4, _363, fa_irr_tex, fa_env_smp) * _1966) * _1971;\n        int _1645 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1645; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _363, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _1935;\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _1935, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1596, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _1966, _1967, _1968, _1969, _1970, _1971, _1972 };\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _363, gl_FragCoord, _599, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _1682 = result;\n    float3 _1683 = _1682 + _1972;\n    result = _1683;\n    float3 param_12 = _1683;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _599);\n    bool _1692 = _363.fa_fog.w > 0.0;\n    bool _1700;\n    if (!_1692)\n    {\n        _1700 = _363.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1700 = _1692;\n    }\n    if (_1700)\n    {\n        float3 _1709 = in.fa_world_pos - _363.fa_camera_pos.xyz;\n        float _1716 = dot(_1709, _363.fa_fog_c.xyz);\n        bool _1720 = _363.fa_fog_c.w > 0.5;\n        float _1721;\n        if (_1720)\n        {\n            _1721 = _1716;\n        }\n        else\n        {\n            _1721 = length(_1709);\n        }\n        float _1733 = _1721 - _363.fa_fog_b.x;\n        if (_1733 > 0.0)\n        {\n            float _1742 = _363.fa_fog.w * _1733;\n            float tau = _1742 * _1742;\n            if (_363.fa_fog_b.y > 0.0)\n            {\n                float _1758;\n                if (_1720)\n                {\n                    _1758 = in.fa_world_pos.y - (_363.fa_fog_c.y * _1716);\n                }\n                else\n                {\n                    _1758 = _363.fa_camera_pos.y;\n                }\n                float _1779 = mix(_1758, in.fa_world_pos.y, fast::clamp(_363.fa_fog_b.x / _1721, 0.0, 1.0));\n                float _1783 = in.fa_world_pos.y - _1779;\n                float _1788 = _1779 - _363.fa_fog_b.z;\n                float _1793 = in.fa_world_pos.y - _363.fa_fog_b.z;\n                bool _1796 = _1788 <= 0.0;\n                bool _1797 = !_1796;\n                bool _1803;\n                if (_1797)\n                {\n                    _1803 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1803 = _1796;\n                }\n                float _1804;\n                if (_1803)\n                {\n                    _1804 = _363.fa_fog_b.y;\n                }\n                else\n                {\n                    _1804 = _363.fa_fog_b.y * exp(-fast::min(_363.fa_fog_b.w * _1788, 80.0));\n                }\n                bool _1831;\n                if (_1797)\n                {\n                    _1831 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1831 = _1796;\n                }\n                float _1832;\n                if (_1831)\n                {\n                    _1832 = _363.fa_fog_b.y * _1788;\n                }\n                else\n                {\n                    _1832 = (_363.fa_fog_b.y * (1.0 - exp(-fast::min(_363.fa_fog_b.w * _1788, 80.0)))) / _363.fa_fog_b.w;\n                }\n                bool _1857 = _1793 <= 0.0;\n                bool _1864;\n                if (!_1857)\n                {\n                    _1864 = _363.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1864 = _1857;\n                }\n                float _1865;\n                if (_1864)\n                {\n                    _1865 = _363.fa_fog_b.y * _1793;\n                }\n                else\n                {\n                    _1865 = (_363.fa_fog_b.y * (1.0 - exp(-fast::min(_363.fa_fog_b.w * _1793, 80.0)))) / _363.fa_fog_b.w;\n                }\n                float _1892;\n                if (abs(_1783) < 0.001000000047497451305389404296875)\n                {\n                    _1892 = _1804;\n                }\n                else\n                {\n                    _1892 = (_1865 - _1832) / _1783;\n                }\n                tau += (_1733 * fast::max(_1892, 0.0));\n            }\n            result = mix(result, _363.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1967);\n    return out;\n}\n\n",
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
            "inst_name": "_363",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
