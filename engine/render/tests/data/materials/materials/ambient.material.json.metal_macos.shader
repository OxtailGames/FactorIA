{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396)\n{\n    bool _401 = _396.fa_cl_info.x < 0.0;\n    bool _408;\n    if (!_401)\n    {\n        _408 = _396.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _408 = _401;\n    }\n    bool _416;\n    if (!_408)\n    {\n        _416 = _396.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _416 = _408;\n    }\n    bool _423;\n    if (!_416)\n    {\n        _423 = _396.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _423 = _416;\n    }\n    bool _430;\n    if (!_423)\n    {\n        _430 = _396.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    if (_430)\n    {\n        return int2(0);\n    }\n    float4 _440 = float4(world_pos, 1.0);\n    float _447 = dot(_396.fa_cl_vpw, _440);\n    if (!(_447 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _469 = float2(dot(_396.fa_cl_vpx, _440), dot(_396.fa_cl_vpy, _440)) / float2(_447);\n    int _473 = int(_396.fa_cl_grid.x);\n    int _477 = int(_396.fa_cl_grid.y);\n    int param = (int(_396.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_396.fa_cl_fwd.xyz, world_pos) + _396.fa_cl_fwd.w, _396.fa_cl_grid.w) / _396.fa_cl_grid.w) * _396.fa_cl_grid.z)), 0, int(_396.fa_cl_info.y) - 1) * _477) + clamp(int(floor(((_469.y * 0.5) + 0.5) * _396.fa_cl_grid.y)), 0, _477 - 1)) * _473)) + clamp(int(floor(((_469.x * 0.5) + 0.5) * _396.fa_cl_grid.x)), 0, _473 - 1);\n    float4 _548 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_548.x), int(_548.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_396.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1293 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _396);\n    fa_cl_slot = _1293.x;\n    fa_cl_local = _1293.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1429 = fa_linear_to_srgb(param);\n        c = _1429;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1437 = fa_srgb_to_linear(param_1);\n            c = _1437;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _160;\n    if (bool(i.front_facing))\n    {\n        _160 = i.world_normal;\n    }\n    else\n    {\n        _160 = -i.world_normal;\n    }\n    float3 _184 = fast::normalize(i.world_tangent.xyz - (_160 * dot(_160, i.world_tangent.xyz)));\n    float3 _212 = fast::normalize(((_184 * m.x) + ((cross(_160, _184) * i.world_tangent.w) * m.y)) + (_160 * m.z));\n    float3 _215;\n    if (bool(i.front_facing))\n    {\n        _215 = _212;\n    }\n    else\n    {\n        _215 = -_212;\n    }\n    return _215;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _396, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _396.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1468 = fa_tex_fix(param_2, param_3);\n    float4 _2424 = base_t;\n    _2424.x = _1468.x;\n    _2424.y = _1468.y;\n    _2424.z = _1468.z;\n    base_t = _2424;\n    float4 _1482 = (_2424 * _396.fa_base_color) * i.vertex_color;\n    float3 _2371 = i.world_normal;\n    if (_396.fa_maps.z > 0.5)\n    {\n        float param_4 = _396.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1514 = fa_tex_fix(param_6, param_7);\n        float3 _1518 = (_1514 * 2.0) - float3(1.0);\n        float2 _1523 = _1518.xy * _396.fa_maps.x;\n        float3 _2432 = _1518;\n        _2432.x = _1523.x;\n        _2432.y = _1523.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2432;\n        _2371 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _396.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1552 = fa_tex_fix(param_12, param_13);\n    float4 _2435 = mrt;\n    _2435.x = _1552.x;\n    _2435.y = _1552.y;\n    _2435.z = _1552.z;\n    mrt = _2435;\n    float4 _1581 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _396.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1581.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1593 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1623 = fa_tex_fix(param_20, param_21);\n    float _2376 = _396.fa_layers_a.x;\n    float _2377 = _396.fa_layers_a.y;\n    float _2380 = _396.fa_layers_a.z;\n    float _2379 = _396.fa_layers_b.w;\n    float _2382 = _396.fa_layers_c.x;\n    if (_396.fa_layers_c.z > 0.5)\n    {\n        if (mod(_396.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2376 *= _1593.y;\n            _2377 *= _1593.z;\n            _2379 *= _1581.w;\n        }\n        if (_396.fa_layers_c.z > 1.5)\n        {\n            _2380 *= mrt.x;\n            _2382 *= mrt.w;\n        }\n    }\n    return Surface{ _1482.xyz, _1482.w, _2371, fast::clamp(_396.fa_pbr.x * _1552.z, 0.0, 1.0), fast::clamp(_396.fa_pbr.y * _1552.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_396.fa_maps.y * (_1593.x - 1.0)), _396.fa_emissive.xyz + (_396.fa_model_emissive.xyz * _1623), _2376, _2377, _396.fa_layers_b.xyz, _2379, _2380, _396.fa_layers_a.w, _2382, _396.fa_layers_c.y, _396.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _396, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_396.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _396.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _396, texturecube<float> fa_irr_tex, sampler fa_env_smp, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _396, fa_irr_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396)\n{\n    int param = (int(_396.fa_cl_info.x) + int(_396.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _396);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _271 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _277 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _280 = _277.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _286 = _280 < 0.5;\n    float3 l;\n    if (_286)\n    {\n        l = fast::normalize(_271.xyz);\n    }\n    else\n    {\n        float3 _298 = _271.xyz - world_pos;\n        float _300 = length(_298);\n        dist = _300;\n        l = _298 / float3(fast::max(_300, 9.9999997473787516355514526367188e-05));\n        float _315 = _300 / fast::max(_271.w, 0.001000000047497451305389404296875);\n        float _321 = fast::clamp(1.0 - (_315 * _315), 0.0, 1.0);\n        atten = _321 * _321;\n        if (_280 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _335 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _345 = _335.w;\n            int param_3 = (li * 4) + 3;\n            float4 _351 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _352 = _351.x;\n            float cos_inner = _352;\n            if (_352 > 1.5)\n            {\n                cos_inner = mix(_345, 1.0, 0.25);\n            }\n            atten *= smoothstep(_345, cos_inner, dot(-l, fast::normalize(_335.xyz)));\n        }\n    }\n    int _382;\n    if (_286)\n    {\n        _382 = 0;\n    }\n    else\n    {\n        _382 = (_280 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _277.xyz * atten, atten, 1.0, dist, _382 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _632)\n{\n    float _622;\n    if (i == 0)\n    {\n        _622 = _632.fa_shadow_split.x;\n    }\n    else\n    {\n        float _638;\n        if (i == 1)\n        {\n            _638 = _632.fa_shadow_split.y;\n        }\n        else\n        {\n            float _646;\n            if (i == 2)\n            {\n                _646 = _632.fa_shadow_split.z;\n            }\n            else\n            {\n                _646 = _632.fa_shadow_split.w;\n            }\n            _638 = _646;\n        }\n        _622 = _638;\n    }\n    return _622;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _610 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_610), sin(_610)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex)\n{\n    float _684 = fast::max(_632.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _689 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _695 = sqrt(1.0 - (_689 * _689));\n    float _703 = fast::min(_695 / fast::max(_689, 0.20000000298023223876953125), 4.0);\n    float _708;\n    if (_632.fa_shadow_bias.y > 0.0)\n    {\n        _708 = _632.fa_shadow_bias.y;\n    }\n    else\n    {\n        _708 = 1.5 * _632.fa_shadow_info[ci].x;\n    }\n    float4 _733 = _632.fa_shadow_mat[ci] * float4(world + (n * (_708 * _695)), 1.0);\n    float _740 = _733.x;\n    bool _743 = _740 < _632.fa_shadow_rect[ci].x;\n    bool _752;\n    if (!_743)\n    {\n        _752 = _740 > _632.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _752 = _743;\n    }\n    bool _761;\n    if (!_752)\n    {\n        _761 = _733.y < _632.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _761 = _752;\n    }\n    bool _770;\n    if (!_761)\n    {\n        _770 = _733.y > _632.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _733.z > 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    if (_777)\n    {\n        return -1.0;\n    }\n    float _786;\n    if (_632.fa_shadow_bias.x > 0.0)\n    {\n        _786 = _632.fa_shadow_bias.x;\n    }\n    else\n    {\n        _786 = 1.5 * _632.fa_shadow_info[ci].x;\n    }\n    float _805 = _733.z - ((_786 * (1.0 + (0.5 * _703))) / _684);\n    float _814 = ((_632.fa_shadow_info[ci].x * fast::min(_703, 3.0)) * 0.5) / _684;\n    int _823 = int(_632.fa_shadow_cfg.z + 0.5);\n    if (_823 == 1)\n    {\n        float2 param = _733.xy;\n        float4 param_1 = _632.fa_shadow_rect[ci];\n        float _834 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_805 <= _834);\n    }\n    float _841 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _844 = _823 == 2;\n    if (_844)\n    {\n        float _858 = fast::clamp(((_632.fa_shadow_cfg.w * _684) * 0.25) / _632.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _841;\n            float2 _877 = fa_shadow_vogel(param_2, param_3, param_4) * _858;\n            float2 param_5 = _733.xy + (_877 * _632.fa_shadow_bias.zw);\n            float4 param_6 = _632.fa_shadow_rect[ci];\n            float _888 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_888 < (_805 - (length(_877) * _814)))\n            {\n                sum += _888;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_805 - (sum / cnt), 0.0) * _684) * _632.fa_shadow_cfg.w) / _632.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _932 = _844 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _932; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _932;\n        float param_9 = _841;\n        float2 _951 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _733.xy + (_951 * _632.fa_shadow_bias.zw);\n        float4 param_11 = _632.fa_shadow_rect[ci];\n        float _962 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_805 - (length(_951) * _814)) <= _962);\n    }\n    return lit / float(_932);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex)\n{\n    if (_396.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _992 = int(_632.fa_shadow_cfg.x + 0.5);\n    if (_992 < 1)\n    {\n        return 1.0;\n    }\n    float _1008 = dot(world - _632.fa_shadow_eye.xyz, _632.fa_shadow_fwd.xyz);\n    int param = _992 - 1;\n    if (_1008 > fa_shadow_split_at(param, _632))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1020 = _992 > 1;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _1008 > _632.fa_shadow_split.x;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 1;\n    }\n    bool _1031 = _992 > 2;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _1008 > _632.fa_shadow_split.y;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 2;\n    }\n    bool _1042 = _992 > 3;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1008 > _632.fa_shadow_split.z;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _992)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1075 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _632, fa_shadow_tex);\n        s = _1075;\n        if (_1075 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_632.fa_shadow_cfg.y > 0.0)\n    {\n        float _1100;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1100 = fa_shadow_split_at(param_5, _632);\n        }\n        else\n        {\n            _1100 = _632.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1119 = _632.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _632) - _1100, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1130 = fast::clamp((_1008 - (fa_shadow_split_at(param_7, _632) - _1119)) / _1119, 0.0, 1.0);\n        if (_1130 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _992)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1151 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _632, fa_shadow_tex);\n                s2 = _1151;\n                if (_1151 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1130);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _1320 = fa_lm.z > 0.5;\n    bool _1326;\n    if (_1320)\n    {\n        int param = li;\n        _1326 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _1326 = _1320;\n    }\n    if (_1326)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1350 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _2356 = _1350.direction;\n    float3 _2351 = _1350.color;\n    float _2353 = _1350.shadow;\n    int _2361 = _1350.type;\n    if ((_2361 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2356;\n        float _1364 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex, fa_world_pos);\n        _2353 = _1364;\n        _2351 *= _1364;\n    }\n    return LightSample{ _2356, _2351, _1350.attenuation, _2353, _1350._distance, _2361 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _632)\n{\n    if (_632.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1175 = int(_632.fa_shadow_cfg.x + 0.5);\n    float _1185 = dot(world - _632.fa_shadow_eye.xyz, _632.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1190 = _1175 > 0;\n    bool _1199;\n    if (_1190)\n    {\n        int param = _1175 - 1;\n        _1199 = _1185 <= fa_shadow_split_at(param, _632);\n    }\n    else\n    {\n        _1199 = _1190;\n    }\n    if (_1199)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1206 = _1175 > 1;\n        bool _1213;\n        if (_1206)\n        {\n            _1213 = _1185 > _632.fa_shadow_split.x;\n        }\n        else\n        {\n            _1213 = _1206;\n        }\n        if (_1213)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1219 = _1175 > 2;\n        bool _1226;\n        if (_1219)\n        {\n            _1226 = _1185 > _632.fa_shadow_split.y;\n        }\n        else\n        {\n            _1226 = _1219;\n        }\n        if (_1226)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1232 = _1175 > 3;\n        bool _1239;\n        if (_1232)\n        {\n            _1239 = _1185 > _632.fa_shadow_split.z;\n        }\n        else\n        {\n            _1239 = _1232;\n        }\n        if (_1239)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _396 [[buffer(1)]], constant fa_shadows& _632 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2167 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2167 = -_2167;\n    }\n    float3 _1768 = fast::normalize(_396.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _396, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n    Surface _1776 = fa_standard_surface(param_1, _396, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2206 = _1776.albedo;\n    float _2207 = _1776.alpha;\n    float3 _2208 = _1776.normal;\n    float _2209 = _1776.metallic;\n    float _2210 = _1776.roughness;\n    float _2211 = _1776.occlusion;\n    float3 _2212 = _1776.emission;\n    float _2213 = _1776.clearcoat;\n    float _2214 = _1776.clearcoat_roughness;\n    float3 _2215 = _1776.sheen_color;\n    float _2216 = _1776.sheen_roughness;\n    float _2217 = _1776.anisotropy;\n    float _2218 = _1776.anisotropy_rotation;\n    float _2219 = _1776.specular;\n    float _2220 = _1776.ior;\n    float3 _2221 = _1776.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n    Surface param_3 = _1776;\n    surface(param_2, param_3);\n    _2206 = param_3.albedo;\n    _2207 = param_3.alpha;\n    _2208 = param_3.normal;\n    _2209 = param_3.metallic;\n    _2210 = param_3.roughness;\n    _2211 = param_3.occlusion;\n    _2212 = param_3.emission;\n    _2213 = param_3.clearcoat;\n    _2214 = param_3.clearcoat_roughness;\n    _2215 = param_3.sheen_color;\n    _2216 = param_3.sheen_roughness;\n    _2217 = param_3.anisotropy;\n    _2218 = param_3.anisotropy_rotation;\n    _2219 = param_3.specular;\n    _2220 = param_3.ior;\n    _2221 = param_3.specular_color;\n    float3 result;\n    if (_396.fa_emissive.w > 0.5)\n    {\n        result = _2206;\n    }\n    else\n    {\n        float3 _1797 = _2208;\n        float3 _1798 = fast::normalize(_1797);\n        _2208 = _1798;\n        float3 param_4 = _1798;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221 };\n        float3 param_7 = fa_indirect_diffuse(param_4, _396, fa_irr_tex, fa_env_smp, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1817 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1817; ln++)\n        {\n            int param_8 = ln;\n            int _1830 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _396, fa_cl_ndir, fa_cl_slot);\n            bool _1833 = in.fa_lm.z > 0.5;\n            bool _1839;\n            if (_1833)\n            {\n                int param_9 = _1830;\n                _1839 = fa_light_baked(param_9, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _1839 = _1833;\n            }\n            if (_1839)\n            {\n                continue;\n            }\n            int param_10 = _1830;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2167;\n            SurfaceInput param_13 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n            Surface param_14 = Surface{ _2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221 };\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _1866 = result;\n    float3 _1867 = _1866 + _2212;\n    result = _1867;\n    float3 param_16 = _1867;\n    float3 param_17 = in.fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17, _632);\n    bool _1876 = _396.fa_fog.w > 0.0;\n    bool _1883;\n    if (!_1876)\n    {\n        _1883 = _396.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1883 = _1876;\n    }\n    if (_1883)\n    {\n        float3 _1892 = in.fa_world_pos - _396.fa_camera_pos.xyz;\n        float _1898 = dot(_1892, _396.fa_fog_c.xyz);\n        bool _1902 = _396.fa_fog_c.w > 0.5;\n        float _1903;\n        if (_1902)\n        {\n            _1903 = _1898;\n        }\n        else\n        {\n            _1903 = length(_1892);\n        }\n        float _1915 = _1903 - _396.fa_fog_b.x;\n        if (_1915 > 0.0)\n        {\n            float _1924 = _396.fa_fog.w * _1915;\n            float tau = _1924 * _1924;\n            if (_396.fa_fog_b.y > 0.0)\n            {\n                float _1940;\n                if (_1902)\n                {\n                    _1940 = in.fa_world_pos.y - (_396.fa_fog_c.y * _1898);\n                }\n                else\n                {\n                    _1940 = _396.fa_camera_pos.y;\n                }\n                float _1961 = mix(_1940, in.fa_world_pos.y, fast::clamp(_396.fa_fog_b.x / _1903, 0.0, 1.0));\n                float _1965 = in.fa_world_pos.y - _1961;\n                float _1970 = _1961 - _396.fa_fog_b.z;\n                float _1975 = in.fa_world_pos.y - _396.fa_fog_b.z;\n                bool _1978 = _1970 <= 0.0;\n                bool _1979 = !_1978;\n                bool _1985;\n                if (_1979)\n                {\n                    _1985 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1985 = _1978;\n                }\n                float _1986;\n                if (_1985)\n                {\n                    _1986 = _396.fa_fog_b.y;\n                }\n                else\n                {\n                    _1986 = _396.fa_fog_b.y * exp(-fast::min(_396.fa_fog_b.w * _1970, 80.0));\n                }\n                bool _2013;\n                if (_1979)\n                {\n                    _2013 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2013 = _1978;\n                }\n                float _2014;\n                if (_2013)\n                {\n                    _2014 = _396.fa_fog_b.y * _1970;\n                }\n                else\n                {\n                    _2014 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _1970, 80.0)))) / _396.fa_fog_b.w;\n                }\n                bool _2039 = _1975 <= 0.0;\n                bool _2046;\n                if (!_2039)\n                {\n                    _2046 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2046 = _2039;\n                }\n                float _2047;\n                if (_2046)\n                {\n                    _2047 = _396.fa_fog_b.y * _1975;\n                }\n                else\n                {\n                    _2047 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _1975, 80.0)))) / _396.fa_fog_b.w;\n                }\n                float _2074;\n                if (abs(_1965) < 0.001000000047497451305389404296875)\n                {\n                    _2074 = _1986;\n                }\n                else\n                {\n                    _2074 = (_2047 - _2014) / _1965;\n                }\n                tau += (_1915 * fast::max(_2074, 0.0));\n            }\n            result = mix(result, _396.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2207);\n    return out;\n}\n\n",
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
            "inst_name": "_396",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_632",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396)\n{\n    bool _401 = _396.fa_cl_info.x < 0.0;\n    bool _408;\n    if (!_401)\n    {\n        _408 = _396.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _408 = _401;\n    }\n    bool _416;\n    if (!_408)\n    {\n        _416 = _396.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _416 = _408;\n    }\n    bool _423;\n    if (!_416)\n    {\n        _423 = _396.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _423 = _416;\n    }\n    bool _430;\n    if (!_423)\n    {\n        _430 = _396.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    if (_430)\n    {\n        return int2(0);\n    }\n    float4 _440 = float4(world_pos, 1.0);\n    float _447 = dot(_396.fa_cl_vpw, _440);\n    if (!(_447 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _469 = float2(dot(_396.fa_cl_vpx, _440), dot(_396.fa_cl_vpy, _440)) / float2(_447);\n    int _473 = int(_396.fa_cl_grid.x);\n    int _477 = int(_396.fa_cl_grid.y);\n    int param = (int(_396.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_396.fa_cl_fwd.xyz, world_pos) + _396.fa_cl_fwd.w, _396.fa_cl_grid.w) / _396.fa_cl_grid.w) * _396.fa_cl_grid.z)), 0, int(_396.fa_cl_info.y) - 1) * _477) + clamp(int(floor(((_469.y * 0.5) + 0.5) * _396.fa_cl_grid.y)), 0, _477 - 1)) * _473)) + clamp(int(floor(((_469.x * 0.5) + 0.5) * _396.fa_cl_grid.x)), 0, _473 - 1);\n    float4 _548 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_548.x), int(_548.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_396.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1293 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _396);\n    fa_cl_slot = _1293.x;\n    fa_cl_local = _1293.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1429 = fa_linear_to_srgb(param);\n        c = _1429;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1437 = fa_srgb_to_linear(param_1);\n            c = _1437;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _160;\n    if (bool(i.front_facing))\n    {\n        _160 = i.world_normal;\n    }\n    else\n    {\n        _160 = -i.world_normal;\n    }\n    float3 _184 = fast::normalize(i.world_tangent.xyz - (_160 * dot(_160, i.world_tangent.xyz)));\n    float3 _212 = fast::normalize(((_184 * m.x) + ((cross(_160, _184) * i.world_tangent.w) * m.y)) + (_160 * m.z));\n    float3 _215;\n    if (bool(i.front_facing))\n    {\n        _215 = _212;\n    }\n    else\n    {\n        _215 = -_212;\n    }\n    return _215;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _396, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _396.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1468 = fa_tex_fix(param_2, param_3);\n    float4 _2424 = base_t;\n    _2424.x = _1468.x;\n    _2424.y = _1468.y;\n    _2424.z = _1468.z;\n    base_t = _2424;\n    float4 _1482 = (_2424 * _396.fa_base_color) * i.vertex_color;\n    float3 _2371 = i.world_normal;\n    if (_396.fa_maps.z > 0.5)\n    {\n        float param_4 = _396.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1514 = fa_tex_fix(param_6, param_7);\n        float3 _1518 = (_1514 * 2.0) - float3(1.0);\n        float2 _1523 = _1518.xy * _396.fa_maps.x;\n        float3 _2432 = _1518;\n        _2432.x = _1523.x;\n        _2432.y = _1523.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2432;\n        _2371 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _396.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1552 = fa_tex_fix(param_12, param_13);\n    float4 _2435 = mrt;\n    _2435.x = _1552.x;\n    _2435.y = _1552.y;\n    _2435.z = _1552.z;\n    mrt = _2435;\n    float4 _1581 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _396.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1581.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1593 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1623 = fa_tex_fix(param_20, param_21);\n    float _2376 = _396.fa_layers_a.x;\n    float _2377 = _396.fa_layers_a.y;\n    float _2380 = _396.fa_layers_a.z;\n    float _2379 = _396.fa_layers_b.w;\n    float _2382 = _396.fa_layers_c.x;\n    if (_396.fa_layers_c.z > 0.5)\n    {\n        if (mod(_396.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2376 *= _1593.y;\n            _2377 *= _1593.z;\n            _2379 *= _1581.w;\n        }\n        if (_396.fa_layers_c.z > 1.5)\n        {\n            _2380 *= mrt.x;\n            _2382 *= mrt.w;\n        }\n    }\n    return Surface{ _1482.xyz, _1482.w, _2371, fast::clamp(_396.fa_pbr.x * _1552.z, 0.0, 1.0), fast::clamp(_396.fa_pbr.y * _1552.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_396.fa_maps.y * (_1593.x - 1.0)), _396.fa_emissive.xyz + (_396.fa_model_emissive.xyz * _1623), _2376, _2377, _396.fa_layers_b.xyz, _2379, _2380, _396.fa_layers_a.w, _2382, _396.fa_layers_c.y, _396.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _396, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_396.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _396.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _396, texturecube<float> fa_irr_tex, sampler fa_env_smp, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _396, fa_irr_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396)\n{\n    int param = (int(_396.fa_cl_info.x) + int(_396.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _396);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _271 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _277 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _280 = _277.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _286 = _280 < 0.5;\n    float3 l;\n    if (_286)\n    {\n        l = fast::normalize(_271.xyz);\n    }\n    else\n    {\n        float3 _298 = _271.xyz - world_pos;\n        float _300 = length(_298);\n        dist = _300;\n        l = _298 / float3(fast::max(_300, 9.9999997473787516355514526367188e-05));\n        float _315 = _300 / fast::max(_271.w, 0.001000000047497451305389404296875);\n        float _321 = fast::clamp(1.0 - (_315 * _315), 0.0, 1.0);\n        atten = _321 * _321;\n        if (_280 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _335 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _345 = _335.w;\n            int param_3 = (li * 4) + 3;\n            float4 _351 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _352 = _351.x;\n            float cos_inner = _352;\n            if (_352 > 1.5)\n            {\n                cos_inner = mix(_345, 1.0, 0.25);\n            }\n            atten *= smoothstep(_345, cos_inner, dot(-l, fast::normalize(_335.xyz)));\n        }\n    }\n    int _382;\n    if (_286)\n    {\n        _382 = 0;\n    }\n    else\n    {\n        _382 = (_280 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _277.xyz * atten, atten, 1.0, dist, _382 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _632)\n{\n    float _622;\n    if (i == 0)\n    {\n        _622 = _632.fa_shadow_split.x;\n    }\n    else\n    {\n        float _638;\n        if (i == 1)\n        {\n            _638 = _632.fa_shadow_split.y;\n        }\n        else\n        {\n            float _646;\n            if (i == 2)\n            {\n                _646 = _632.fa_shadow_split.z;\n            }\n            else\n            {\n                _646 = _632.fa_shadow_split.w;\n            }\n            _638 = _646;\n        }\n        _622 = _638;\n    }\n    return _622;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _610 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_610), sin(_610)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex)\n{\n    float _684 = fast::max(_632.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _689 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _695 = sqrt(1.0 - (_689 * _689));\n    float _703 = fast::min(_695 / fast::max(_689, 0.20000000298023223876953125), 4.0);\n    float _708;\n    if (_632.fa_shadow_bias.y > 0.0)\n    {\n        _708 = _632.fa_shadow_bias.y;\n    }\n    else\n    {\n        _708 = 1.5 * _632.fa_shadow_info[ci].x;\n    }\n    float4 _733 = _632.fa_shadow_mat[ci] * float4(world + (n * (_708 * _695)), 1.0);\n    float _740 = _733.x;\n    bool _743 = _740 < _632.fa_shadow_rect[ci].x;\n    bool _752;\n    if (!_743)\n    {\n        _752 = _740 > _632.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _752 = _743;\n    }\n    bool _761;\n    if (!_752)\n    {\n        _761 = _733.y < _632.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _761 = _752;\n    }\n    bool _770;\n    if (!_761)\n    {\n        _770 = _733.y > _632.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _733.z > 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    if (_777)\n    {\n        return -1.0;\n    }\n    float _786;\n    if (_632.fa_shadow_bias.x > 0.0)\n    {\n        _786 = _632.fa_shadow_bias.x;\n    }\n    else\n    {\n        _786 = 1.5 * _632.fa_shadow_info[ci].x;\n    }\n    float _805 = _733.z - ((_786 * (1.0 + (0.5 * _703))) / _684);\n    float _814 = ((_632.fa_shadow_info[ci].x * fast::min(_703, 3.0)) * 0.5) / _684;\n    int _823 = int(_632.fa_shadow_cfg.z + 0.5);\n    if (_823 == 1)\n    {\n        float2 param = _733.xy;\n        float4 param_1 = _632.fa_shadow_rect[ci];\n        float _834 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_805 <= _834);\n    }\n    float _841 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _844 = _823 == 2;\n    if (_844)\n    {\n        float _858 = fast::clamp(((_632.fa_shadow_cfg.w * _684) * 0.25) / _632.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _841;\n            float2 _877 = fa_shadow_vogel(param_2, param_3, param_4) * _858;\n            float2 param_5 = _733.xy + (_877 * _632.fa_shadow_bias.zw);\n            float4 param_6 = _632.fa_shadow_rect[ci];\n            float _888 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_888 < (_805 - (length(_877) * _814)))\n            {\n                sum += _888;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_805 - (sum / cnt), 0.0) * _684) * _632.fa_shadow_cfg.w) / _632.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _932 = _844 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _932; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _932;\n        float param_9 = _841;\n        float2 _951 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _733.xy + (_951 * _632.fa_shadow_bias.zw);\n        float4 param_11 = _632.fa_shadow_rect[ci];\n        float _962 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_805 - (length(_951) * _814)) <= _962);\n    }\n    return lit / float(_932);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex)\n{\n    if (_396.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _992 = int(_632.fa_shadow_cfg.x + 0.5);\n    if (_992 < 1)\n    {\n        return 1.0;\n    }\n    float _1008 = dot(world - _632.fa_shadow_eye.xyz, _632.fa_shadow_fwd.xyz);\n    int param = _992 - 1;\n    if (_1008 > fa_shadow_split_at(param, _632))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1020 = _992 > 1;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _1008 > _632.fa_shadow_split.x;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 1;\n    }\n    bool _1031 = _992 > 2;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _1008 > _632.fa_shadow_split.y;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 2;\n    }\n    bool _1042 = _992 > 3;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1008 > _632.fa_shadow_split.z;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _992)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1075 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _632, fa_shadow_tex);\n        s = _1075;\n        if (_1075 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_632.fa_shadow_cfg.y > 0.0)\n    {\n        float _1100;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1100 = fa_shadow_split_at(param_5, _632);\n        }\n        else\n        {\n            _1100 = _632.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1119 = _632.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _632) - _1100, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1130 = fast::clamp((_1008 - (fa_shadow_split_at(param_7, _632) - _1119)) / _1119, 0.0, 1.0);\n        if (_1130 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _992)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1151 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _632, fa_shadow_tex);\n                s2 = _1151;\n                if (_1151 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1130);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _396, thread float4& gl_FragCoord, constant fa_shadows& _632, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _1320 = fa_lm.z > 0.5;\n    bool _1326;\n    if (_1320)\n    {\n        int param = li;\n        _1326 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _1326 = _1320;\n    }\n    if (_1326)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1350 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _2356 = _1350.direction;\n    float3 _2351 = _1350.color;\n    float _2353 = _1350.shadow;\n    int _2361 = _1350.type;\n    if ((_2361 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2356;\n        float _1364 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex, fa_world_pos);\n        _2353 = _1364;\n        _2351 *= _1364;\n    }\n    return LightSample{ _2356, _2351, _1350.attenuation, _2353, _1350._distance, _2361 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _632)\n{\n    if (_632.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1175 = int(_632.fa_shadow_cfg.x + 0.5);\n    float _1185 = dot(world - _632.fa_shadow_eye.xyz, _632.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1190 = _1175 > 0;\n    bool _1199;\n    if (_1190)\n    {\n        int param = _1175 - 1;\n        _1199 = _1185 <= fa_shadow_split_at(param, _632);\n    }\n    else\n    {\n        _1199 = _1190;\n    }\n    if (_1199)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1206 = _1175 > 1;\n        bool _1213;\n        if (_1206)\n        {\n            _1213 = _1185 > _632.fa_shadow_split.x;\n        }\n        else\n        {\n            _1213 = _1206;\n        }\n        if (_1213)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1219 = _1175 > 2;\n        bool _1226;\n        if (_1219)\n        {\n            _1226 = _1185 > _632.fa_shadow_split.y;\n        }\n        else\n        {\n            _1226 = _1219;\n        }\n        if (_1226)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1232 = _1175 > 3;\n        bool _1239;\n        if (_1232)\n        {\n            _1239 = _1185 > _632.fa_shadow_split.z;\n        }\n        else\n        {\n            _1239 = _1232;\n        }\n        if (_1239)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _396 [[buffer(1)]], constant fa_shadows& _632 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2167 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2167 = -_2167;\n    }\n    float3 _1768 = fast::normalize(_396.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _396, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n    Surface _1776 = fa_standard_surface(param_1, _396, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2206 = _1776.albedo;\n    float _2207 = _1776.alpha;\n    float3 _2208 = _1776.normal;\n    float _2209 = _1776.metallic;\n    float _2210 = _1776.roughness;\n    float _2211 = _1776.occlusion;\n    float3 _2212 = _1776.emission;\n    float _2213 = _1776.clearcoat;\n    float _2214 = _1776.clearcoat_roughness;\n    float3 _2215 = _1776.sheen_color;\n    float _2216 = _1776.sheen_roughness;\n    float _2217 = _1776.anisotropy;\n    float _2218 = _1776.anisotropy_rotation;\n    float _2219 = _1776.specular;\n    float _2220 = _1776.ior;\n    float3 _2221 = _1776.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n    Surface param_3 = _1776;\n    surface(param_2, param_3);\n    _2206 = param_3.albedo;\n    _2207 = param_3.alpha;\n    _2208 = param_3.normal;\n    _2209 = param_3.metallic;\n    _2210 = param_3.roughness;\n    _2211 = param_3.occlusion;\n    _2212 = param_3.emission;\n    _2213 = param_3.clearcoat;\n    _2214 = param_3.clearcoat_roughness;\n    _2215 = param_3.sheen_color;\n    _2216 = param_3.sheen_roughness;\n    _2217 = param_3.anisotropy;\n    _2218 = param_3.anisotropy_rotation;\n    _2219 = param_3.specular;\n    _2220 = param_3.ior;\n    _2221 = param_3.specular_color;\n    float3 result;\n    if (_396.fa_emissive.w > 0.5)\n    {\n        result = _2206;\n    }\n    else\n    {\n        float3 _1797 = _2208;\n        float3 _1798 = fast::normalize(_1797);\n        _2208 = _1798;\n        float3 param_4 = _1798;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221 };\n        float3 param_7 = fa_indirect_diffuse(param_4, _396, fa_irr_tex, fa_env_smp, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1817 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1817; ln++)\n        {\n            int param_8 = ln;\n            int _1830 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _396, fa_cl_ndir, fa_cl_slot);\n            bool _1833 = in.fa_lm.z > 0.5;\n            bool _1839;\n            if (_1833)\n            {\n                int param_9 = _1830;\n                _1839 = fa_light_baked(param_9, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _1839 = _1833;\n            }\n            if (_1839)\n            {\n                continue;\n            }\n            int param_10 = _1830;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2167;\n            SurfaceInput param_13 = SurfaceInput{ in.fa_world_pos, _2167, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1768, short(gl_FrontFacing) };\n            Surface param_14 = Surface{ _2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221 };\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _396, gl_FragCoord, _632, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _1866 = result;\n    float3 _1867 = _1866 + _2212;\n    result = _1867;\n    float3 param_16 = _1867;\n    float3 param_17 = in.fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17, _632);\n    bool _1876 = _396.fa_fog.w > 0.0;\n    bool _1883;\n    if (!_1876)\n    {\n        _1883 = _396.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1883 = _1876;\n    }\n    if (_1883)\n    {\n        float3 _1892 = in.fa_world_pos - _396.fa_camera_pos.xyz;\n        float _1898 = dot(_1892, _396.fa_fog_c.xyz);\n        bool _1902 = _396.fa_fog_c.w > 0.5;\n        float _1903;\n        if (_1902)\n        {\n            _1903 = _1898;\n        }\n        else\n        {\n            _1903 = length(_1892);\n        }\n        float _1915 = _1903 - _396.fa_fog_b.x;\n        if (_1915 > 0.0)\n        {\n            float _1924 = _396.fa_fog.w * _1915;\n            float tau = _1924 * _1924;\n            if (_396.fa_fog_b.y > 0.0)\n            {\n                float _1940;\n                if (_1902)\n                {\n                    _1940 = in.fa_world_pos.y - (_396.fa_fog_c.y * _1898);\n                }\n                else\n                {\n                    _1940 = _396.fa_camera_pos.y;\n                }\n                float _1961 = mix(_1940, in.fa_world_pos.y, fast::clamp(_396.fa_fog_b.x / _1903, 0.0, 1.0));\n                float _1965 = in.fa_world_pos.y - _1961;\n                float _1970 = _1961 - _396.fa_fog_b.z;\n                float _1975 = in.fa_world_pos.y - _396.fa_fog_b.z;\n                bool _1978 = _1970 <= 0.0;\n                bool _1979 = !_1978;\n                bool _1985;\n                if (_1979)\n                {\n                    _1985 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1985 = _1978;\n                }\n                float _1986;\n                if (_1985)\n                {\n                    _1986 = _396.fa_fog_b.y;\n                }\n                else\n                {\n                    _1986 = _396.fa_fog_b.y * exp(-fast::min(_396.fa_fog_b.w * _1970, 80.0));\n                }\n                bool _2013;\n                if (_1979)\n                {\n                    _2013 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2013 = _1978;\n                }\n                float _2014;\n                if (_2013)\n                {\n                    _2014 = _396.fa_fog_b.y * _1970;\n                }\n                else\n                {\n                    _2014 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _1970, 80.0)))) / _396.fa_fog_b.w;\n                }\n                bool _2039 = _1975 <= 0.0;\n                bool _2046;\n                if (!_2039)\n                {\n                    _2046 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2046 = _2039;\n                }\n                float _2047;\n                if (_2046)\n                {\n                    _2047 = _396.fa_fog_b.y * _1975;\n                }\n                else\n                {\n                    _2047 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _1975, 80.0)))) / _396.fa_fog_b.w;\n                }\n                float _2074;\n                if (abs(_1965) < 0.001000000047497451305389404296875)\n                {\n                    _2074 = _1986;\n                }\n                else\n                {\n                    _2074 = (_2047 - _2014) / _1965;\n                }\n                tau += (_1915 * fast::max(_2074, 0.0));\n            }\n            result = mix(result, _396.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2207);\n    return out;\n}\n\n",
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
            "inst_name": "_396",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_632",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
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
