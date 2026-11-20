{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_546.x), int(_546.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1476 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _174;\n    if (bool(i.front_facing))\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = fast::normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = fast::normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (bool(i.front_facing))\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1762 = fa_tex_fix(param_2, param_3);\n    float4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    float4 _1776 = (_2418 * _394.fa_base_color) * i.vertex_color;\n    float3 _2377 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1808 = fa_tex_fix(param_6, param_7);\n        float3 _1812 = (_1808 * 2.0) - float3(1.0);\n        float2 _1817 = _1812.xy * _394.fa_maps.x;\n        float3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1846 = fa_tex_fix(param_12, param_13);\n    float4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1912 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1776.xyz, _1776.w, _2377, fast::clamp(_394.fa_pbr.x * _1846.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _1846.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_1885.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _1912) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _266 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _272 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _275 = _272.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _282 = _275 < 0.5;\n    float3 l;\n    if (_282)\n    {\n        l = fast::normalize(_266.xyz);\n    }\n    else\n    {\n        float3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / float3(fast::max(_296, 9.9999997473787516355514526367188e-05));\n        float _311 = _296 / fast::max(_266.w, 0.001000000047497451305389404296875);\n        float _317 = fast::clamp(1.0 - (_311 * _311), 0.0, 1.0);\n        atten = _317 * _317;\n        if (_275 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _331 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            float4 _348 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5)\n            {\n                cos_inner = mix(_341, 1.0, 0.25);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, fast::normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _272.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _630)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630.fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630.fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630.fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630.fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    float _682 = fast::max(_630.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _687 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _693 = sqrt(1.0 - (_687 * _687));\n    float _701 = fast::min(_693 / fast::max(_687, 0.20000000298023223876953125), 4.0);\n    float _706;\n    if (_630.fa_shadow_bias.y > 0.0)\n    {\n        _706 = _630.fa_shadow_bias.y;\n    }\n    else\n    {\n        _706 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float4 _731 = _630.fa_shadow_mat[ci] * float4(world + (n * (_706 * _693)), 1.0);\n    float _738 = _731.x;\n    bool _741 = _738 < _630.fa_shadow_rect[ci].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > _630.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < _630.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > _630.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0;\n    }\n    float _784;\n    if (_630.fa_shadow_bias.x > 0.0)\n    {\n        _784 = _630.fa_shadow_bias.x;\n    }\n    else\n    {\n        _784 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0 + (0.5 * _701))) / _682);\n    float _812 = ((_630.fa_shadow_info[ci].x * fast::min(_701, 3.0)) * 0.5) / _682;\n    int _821 = int(_630.fa_shadow_cfg.z + 0.5);\n    if (_821 == 1)\n    {\n        float2 param = _731.xy;\n        float4 param_1 = _630.fa_shadow_rect[ci];\n        float _832 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = fast::clamp(((_630.fa_shadow_cfg.w * _682) * 0.25) / _630.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            float2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            float2 param_5 = _731.xy + (_875 * _630.fa_shadow_bias.zw);\n            float4 param_6 = _630.fa_shadow_rect[ci];\n            float _886 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_803 - (sum / cnt), 0.0) * _682) * _630.fa_shadow_cfg.w) / _630.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        float2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _731.xy + (_949 * _630.fa_shadow_bias.zw);\n        float4 param_11 = _630.fa_shadow_rect[ci];\n        float _960 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _990 = int(_630.fa_shadow_cfg.x + 0.5);\n    if (_990 < 1)\n    {\n        return 1.0;\n    }\n    float _1006 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param, _630))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > _630.fa_shadow_split.x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > _630.fa_shadow_split.y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > _630.fa_shadow_split.z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n        s = _1073;\n        if (_1073 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_630.fa_shadow_cfg.y > 0.0)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5, _630);\n        }\n        else\n        {\n            _1098 = _630.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1117 = _630.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _630) - _1098, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1128 = fast::clamp((_1006 - (fa_shadow_split_at(param_7, _630) - _1117)) / _1117, 0.0, 1.0);\n        if (_1128 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n                s2 = _1149;\n                if (_1149 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2353 = _1504.direction;\n    float3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    return LightSample{ _2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1363 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1366 = _1363.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1366 * _1366, exp2((-9.27999973297119140625) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _394.fa_env_horizon.w)).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625 * _1286;\n    return mix(mix(_394.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_394.fa_env_horizon.xyz, _394.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1286)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1316, 0.0500000007450580596923828125 + _1316, d.y))), ((_394.fa_env_sky.xyz + _394.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1286 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1405 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _394, fa_env_tex, fa_env_smp) * ((f0 * _1405.x) + float3(_1405.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _394, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _1651)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    float3 lit = (_394.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5)\n        {\n            _1645 = 1.0;\n        }\n        else\n        {\n            _1645 = _1651.dark;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _394, fa_env_tex, fa_env_smp) * _1651.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _630)\n{\n    if (_630.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1173 = int(_630.fa_shadow_cfg.x + 0.5);\n    float _1183 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param, _630);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > _630.fa_shadow_split.x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > _630.fa_shadow_split.y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > _630.fa_shadow_split.z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_material& _1651 [[buffer(5)]], constant fa_shadows& _630 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2253 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    float3 _1955 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n    Surface _1963 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    float3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    float3 _2290 = _1963.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2284;\n    }\n    else\n    {\n        float3 _1984 = _2286;\n        float3 _1985 = fast::normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2284, _2285, _1985, _2287, _2288, _2289, _2290 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, _1651);\n    }\n    float3 _2000 = result;\n    float3 _2001 = _2000 + _2290;\n    result = _2001;\n    float3 param_6 = _2001;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _630);\n    bool _2010 = _394.fa_fog.w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2027 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2034 = dot(_2027, _394.fa_fog_c.xyz);\n        bool _2038 = _394.fa_fog_c.w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - _394.fa_fog_b.x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = _394.fa_fog.w * _2051;\n            float tau = _2060 * _2060;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2034);\n                }\n                else\n                {\n                    _2076 = _394.fa_camera_pos.y;\n                }\n                float _2097 = mix(_2076, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2039, 0.0, 1.0));\n                float _2101 = in.fa_world_pos.y - _2097;\n                float _2106 = _2097 - _394.fa_fog_b.z;\n                float _2111 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2122 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = _394.fa_fog_b.y * _2106;\n                }\n                else\n                {\n                    _2150 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2106, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = _394.fa_fog_b.y * _2111;\n                }\n                else\n                {\n                    _2183 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2111, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * fast::max(_2210, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2285);\n    return out;\n}\n\n",
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
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_546.x), int(_546.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1476 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _174;\n    if (bool(i.front_facing))\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = fast::normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = fast::normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (bool(i.front_facing))\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1762 = fa_tex_fix(param_2, param_3);\n    float4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    float4 _1776 = (_2418 * _394.fa_base_color) * i.vertex_color;\n    float3 _2377 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1808 = fa_tex_fix(param_6, param_7);\n        float3 _1812 = (_1808 * 2.0) - float3(1.0);\n        float2 _1817 = _1812.xy * _394.fa_maps.x;\n        float3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1846 = fa_tex_fix(param_12, param_13);\n    float4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1912 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1776.xyz, _1776.w, _2377, fast::clamp(_394.fa_pbr.x * _1846.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _1846.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_1885.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _1912) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _266 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _272 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _275 = _272.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _282 = _275 < 0.5;\n    float3 l;\n    if (_282)\n    {\n        l = fast::normalize(_266.xyz);\n    }\n    else\n    {\n        float3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / float3(fast::max(_296, 9.9999997473787516355514526367188e-05));\n        float _311 = _296 / fast::max(_266.w, 0.001000000047497451305389404296875);\n        float _317 = fast::clamp(1.0 - (_311 * _311), 0.0, 1.0);\n        atten = _317 * _317;\n        if (_275 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _331 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            float4 _348 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5)\n            {\n                cos_inner = mix(_341, 1.0, 0.25);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, fast::normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _272.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _630)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630.fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630.fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630.fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630.fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    float _682 = fast::max(_630.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _687 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _693 = sqrt(1.0 - (_687 * _687));\n    float _701 = fast::min(_693 / fast::max(_687, 0.20000000298023223876953125), 4.0);\n    float _706;\n    if (_630.fa_shadow_bias.y > 0.0)\n    {\n        _706 = _630.fa_shadow_bias.y;\n    }\n    else\n    {\n        _706 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float4 _731 = _630.fa_shadow_mat[ci] * float4(world + (n * (_706 * _693)), 1.0);\n    float _738 = _731.x;\n    bool _741 = _738 < _630.fa_shadow_rect[ci].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > _630.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < _630.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > _630.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0;\n    }\n    float _784;\n    if (_630.fa_shadow_bias.x > 0.0)\n    {\n        _784 = _630.fa_shadow_bias.x;\n    }\n    else\n    {\n        _784 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0 + (0.5 * _701))) / _682);\n    float _812 = ((_630.fa_shadow_info[ci].x * fast::min(_701, 3.0)) * 0.5) / _682;\n    int _821 = int(_630.fa_shadow_cfg.z + 0.5);\n    if (_821 == 1)\n    {\n        float2 param = _731.xy;\n        float4 param_1 = _630.fa_shadow_rect[ci];\n        float _832 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = fast::clamp(((_630.fa_shadow_cfg.w * _682) * 0.25) / _630.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            float2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            float2 param_5 = _731.xy + (_875 * _630.fa_shadow_bias.zw);\n            float4 param_6 = _630.fa_shadow_rect[ci];\n            float _886 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_803 - (sum / cnt), 0.0) * _682) * _630.fa_shadow_cfg.w) / _630.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        float2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _731.xy + (_949 * _630.fa_shadow_bias.zw);\n        float4 param_11 = _630.fa_shadow_rect[ci];\n        float _960 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _990 = int(_630.fa_shadow_cfg.x + 0.5);\n    if (_990 < 1)\n    {\n        return 1.0;\n    }\n    float _1006 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param, _630))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > _630.fa_shadow_split.x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > _630.fa_shadow_split.y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > _630.fa_shadow_split.z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n        s = _1073;\n        if (_1073 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_630.fa_shadow_cfg.y > 0.0)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5, _630);\n        }\n        else\n        {\n            _1098 = _630.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1117 = _630.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _630) - _1098, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1128 = fast::clamp((_1006 - (fa_shadow_split_at(param_7, _630) - _1117)) / _1117, 0.0, 1.0);\n        if (_1128 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n                s2 = _1149;\n                if (_1149 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2353 = _1504.direction;\n    float3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    return LightSample{ _2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1363 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1366 = _1363.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1366 * _1366, exp2((-9.27999973297119140625) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _394.fa_env_horizon.w)).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625 * _1286;\n    return mix(mix(_394.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_394.fa_env_horizon.xyz, _394.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1286)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1316, 0.0500000007450580596923828125 + _1316, d.y))), ((_394.fa_env_sky.xyz + _394.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1286 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1405 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _394, fa_env_tex, fa_env_smp) * ((f0 * _1405.x) + float3(_1405.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _394, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _394, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _1651)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    float3 lit = (_394.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5)\n        {\n            _1645 = 1.0;\n        }\n        else\n        {\n            _1645 = _1651.dark;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _394, fa_env_tex, fa_env_smp) * _1651.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _630)\n{\n    if (_630.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1173 = int(_630.fa_shadow_cfg.x + 0.5);\n    float _1183 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param, _630);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > _630.fa_shadow_split.x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > _630.fa_shadow_split.y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > _630.fa_shadow_split.z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_material& _1651 [[buffer(5)]], constant fa_shadows& _630 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2253 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    float3 _1955 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n    Surface _1963 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    float3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    float3 _2290 = _1963.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2284;\n    }\n    else\n    {\n        float3 _1984 = _2286;\n        float3 _1985 = fast::normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2253, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1955, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2284, _2285, _1985, _2287, _2288, _2289, _2290 };\n        result = lighting(param_4, param_5, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_env_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local, _1651);\n    }\n    float3 _2000 = result;\n    float3 _2001 = _2000 + _2290;\n    result = _2001;\n    float3 param_6 = _2001;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _630);\n    bool _2010 = _394.fa_fog.w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2027 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2034 = dot(_2027, _394.fa_fog_c.xyz);\n        bool _2038 = _394.fa_fog_c.w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - _394.fa_fog_b.x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = _394.fa_fog.w * _2051;\n            float tau = _2060 * _2060;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2034);\n                }\n                else\n                {\n                    _2076 = _394.fa_camera_pos.y;\n                }\n                float _2097 = mix(_2076, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2039, 0.0, 1.0));\n                float _2101 = in.fa_world_pos.y - _2097;\n                float _2106 = _2097 - _394.fa_fog_b.z;\n                float _2111 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2122 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = _394.fa_fog_b.y * _2106;\n                }\n                else\n                {\n                    _2150 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2106, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = _394.fa_fog_b.y * _2111;\n                }\n                else\n                {\n                    _2183 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2111, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * fast::max(_2210, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2285);\n    return out;\n}\n\n",
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
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213.fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _571, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _518 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _518, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _518, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213.fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _571, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _518 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _518, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _518, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
