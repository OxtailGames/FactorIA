{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _153.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    bool _421 = _416.fa_cl_info.x < 0.0;\n    bool _428;\n    if (!_421)\n    {\n        _428 = _416.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = _416.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = _416.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = _416.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return float4(0.0);\n    }\n    float4 _460 = float4(world_pos, 1.0);\n    float _467 = dot(_416.fa_cl_vpw, _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _489 = float2(dot(_416.fa_cl_vpx, _460), dot(_416.fa_cl_vpy, _460)) / float2(_467);\n    int _493 = int(_416.fa_cl_grid.x);\n    int _497 = int(_416.fa_cl_grid.y);\n    int param = (int(_416.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_416.fa_cl_fwd.xyz, world_pos) + _416.fa_cl_fwd.w, _416.fa_cl_grid.w) / _416.fa_cl_grid.w) * _416.fa_cl_grid.z)), 0, int(_416.fa_cl_info.y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5) + 0.5) * _416.fa_cl_grid.y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5) + 0.5) * _416.fa_cl_grid.x)), 0, _493 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    float3 param = world_pos;\n    float4 _573 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _416);\n    return int2(int(_573.x), int(_573.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_416.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1971 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _416);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _188;\n    if (bool(i.front_facing))\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    float3 _212 = fast::normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    float3 _240 = fast::normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    float3 _243;\n    if (bool(i.front_facing))\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _416, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _416.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2129 = fa_tex_fix(param_2, param_3);\n    float4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    float4 _2143 = (_2974 * _416.fa_base_color) * i.vertex_color;\n    float3 _2898 = i.world_normal;\n    if (_416.fa_maps.z > 0.5)\n    {\n        float param_4 = _416.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2175 = fa_tex_fix(param_6, param_7);\n        float3 _2178 = (_2175 * 2.0) - float3(1.0);\n        float2 _2183 = _2178.xy * _416.fa_maps.x;\n        float3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _416.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2212 = fa_tex_fix(param_12, param_13);\n    float4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = _416.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2278 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2143.xyz, _2143.w, _2898, fast::clamp(_416.fa_pbr.x * _2212.z, 0.0, 1.0), fast::clamp(_416.fa_pbr.y * _2212.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_416.fa_maps.y * (_2251.x - 1.0)), _416.fa_emissive.xyz + (_416.fa_model_emissive.xyz * _2278) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _2038)\n{\n    s.emission += ((tint.xyz * tint.w) * _2038.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _654 = rect.zw - rect.xy;\n    float2 _658 = _654 * atlas;\n    float2 _662 = ddx * _658;\n    float2 _666 = ddy * _658;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _654)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _701 = dfdx(world_pos);\n    float3 _704 = dfdy(world_pos);\n    bool _707 = _416.fa_counts.y < 0.5;\n    bool _714;\n    if (!_707)\n    {\n        _714 = _416.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _721 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _416);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(_416.fa_counts.y + 0.5);\n    int param_1 = _735;\n    float4 _739 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    float4 _751 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _752 = _751.x;\n    int _758 = int(_416.fa_counts.w + 0.5) - 1;\n    int _762 = int(_721.z);\n    float3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        float4 _798 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_798.w + 0.5) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        float4 _813 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _793 + 1;\n        float4 _818 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _793 + 2;\n        float4 _823 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        float3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        float3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = fast::clamp(dot(geo_normal, fast::normalize(_840)) * _798.z, 0.0, 1.0);\n        if (_881 <= 0.0)\n        {\n            continue;\n        }\n        float _901 = (fast::clamp((0.5 - abs(_845)) * 10.0, 0.0, 1.0) * _881) * _798.x;\n        float2 _909 = float2(_831 + 0.5, 0.5 - _838);\n        float2 _919 = float2(dot(_826, _701), dot(_833, _701));\n        float2 _929 = float2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        float4 _934 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _793 + 3;\n        float4 _939 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _793 + 4;\n        float4 _944 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            float4 param_11 = _939;\n            float2 param_12 = _909;\n            float2 param_13 = _742;\n            float2 param_14 = _919;\n            float2 param_15 = _929;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_752 > 0.5) && (_752 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _980 = fa_dc_to_linear(param_16);\n                float4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_901 * tex_a) * _934.w, 0.0, 1.0)));\n        if (_944.z > _944.x)\n        {\n            float4 param_17 = _944;\n            float2 param_18 = _909;\n            float2 param_19 = _742;\n            float2 param_20 = _919;\n            float2 param_21 = _929;\n            float4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_752 > 1.5)\n            {\n                float3 param_22 = _1024.xyz;\n                float3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            float3 _1044 = (_1028 * 2.0) - float3(1.0);\n            float2 _1049 = _1044.xy * _798.y;\n            float3 _1071 = (fast::normalize(_826) * _1049.x) + (fast::normalize(_833) * _1049.y);\n            float3 _1074 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1074, fast::normalize((_1074 * fast::max(_1044.z, 0.0500000007450580596923828125)) + (_1071 - (_1074 * dot(_1074, _1071)))), float3(fast::clamp(_901 * (_954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_416.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _416.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    int param = (int(_416.fa_cl_info.x) + int(_416.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _416);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    float3 l;\n    if (_304)\n    {\n        l = fast::normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / float3(fast::max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / fast::max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = fast::clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, fast::normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _294.xyz * atten, atten, 1.0, dist, _402 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1156)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = _1156.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = _1156.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = _1156.fa_shadow_split.z;\n            }\n            else\n            {\n                _1170 = _1156.fa_shadow_split.w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex)\n{\n    float _1208 = fast::max(_1156.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1213 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1219 = sqrt(1.0 - (_1213 * _1213));\n    float _1226 = fast::min(_1219 / fast::max(_1213, 0.20000000298023223876953125), 4.0);\n    float _1231;\n    if (_1156.fa_shadow_bias.y > 0.0)\n    {\n        _1231 = _1156.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1231 = 1.5 * _1156.fa_shadow_info[ci].x;\n    }\n    float4 _1256 = _1156.fa_shadow_mat[ci] * float4(world + (n * (_1231 * _1219)), 1.0);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < _1156.fa_shadow_rect[ci].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > _1156.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < _1156.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > _1156.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0;\n    }\n    float _1309;\n    if (_1156.fa_shadow_bias.x > 0.0)\n    {\n        _1309 = _1156.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1309 = 1.5 * _1156.fa_shadow_info[ci].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0 + (0.5 * _1226))) / _1208);\n    float _1337 = ((_1156.fa_shadow_info[ci].x * fast::min(_1226, 3.0)) * 0.5) / _1208;\n    int _1346 = int(_1156.fa_shadow_cfg.z + 0.5);\n    if (_1346 == 1)\n    {\n        float2 param = _1256.xy;\n        float4 param_1 = _1156.fa_shadow_rect[ci];\n        float _1357 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = fast::clamp(((_1156.fa_shadow_cfg.w * _1208) * 0.25) / _1156.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            float2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            float2 param_5 = _1256.xy + (_1400 * _1156.fa_shadow_bias.zw);\n            float4 param_6 = _1156.fa_shadow_rect[ci];\n            float _1411 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1328 - (sum / cnt), 0.0) * _1208) * _1156.fa_shadow_cfg.w) / _1156.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        float2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1256.xy + (_1474 * _1156.fa_shadow_bias.zw);\n        float4 param_11 = _1156.fa_shadow_rect[ci];\n        float _1485 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex)\n{\n    if (_416.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1515 = int(_1156.fa_shadow_cfg.x + 0.5);\n    if (_1515 < 1)\n    {\n        return 1.0;\n    }\n    float _1530 = dot(world - _1156.fa_shadow_eye.xyz, _1156.fa_shadow_fwd.xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param, _1156))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > _1156.fa_shadow_split.x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > _1156.fa_shadow_split.y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > _1156.fa_shadow_split.z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1156, fa_shadow_tex);\n        s = _1597;\n        if (_1597 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1156.fa_shadow_cfg.y > 0.0)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5, _1156);\n        }\n        else\n        {\n            _1622 = _1156.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1641 = _1156.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1156) - _1622, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1652 = fast::clamp((_1530 - (fa_shadow_split_at(param_7, _1156) - _1641)) / _1641, 0.0, 1.0);\n        if (_1652 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1156, fa_shadow_tex);\n                s2 = _1673;\n                if (_1673 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2883 = _1999.direction;\n    float3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex, fa_world_pos);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    return LightSample{ _2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1903 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1906 = _1903.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1906 * _1906, exp2((-9.27999973297119140625) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_416.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _416.fa_env_horizon.w)).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625 * _1809;\n    return mix(mix(_416.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_416.fa_env_horizon.xyz, _416.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1809)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1839, 0.0500000007450580596923828125 + _1839, d.y))), ((_416.fa_env_sky.xyz + _416.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1809 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1945 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _416, fa_env_smp, fa_env_tex) * ((f0 * _1945.x) + float3(_1945.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1156)\n{\n    if (_1156.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1697 = int(_1156.fa_shadow_cfg.x + 0.5);\n    float _1707 = dot(world - _1156.fa_shadow_eye.xyz, _1156.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param, _1156);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > _1156.fa_shadow_split.x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > _1156.fa_shadow_split.y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > _1156.fa_shadow_split.z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _416 [[buffer(1)]], constant fa_material& _2038 [[buffer(5)]], constant fa_shadows& _1156 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2803 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    float3 _2321 = fast::normalize(_416.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _416, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2803, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2321, short(gl_FrontFacing) };\n    Surface _2329 = fa_standard_surface(param_1, _416, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    float3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    float3 _2832 = _2329.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2803, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2321, short(gl_FrontFacing) };\n    Surface param_3 = _2329;\n    surface(param_2, param_3, tint, _2038);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2803;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _416, fa_decal_tex, fa_env_smp);\n    _2826 = param_6;\n    _2828 = param_7;\n    float3 result;\n    if (_416.fa_emissive.w > 0.5)\n    {\n        result = _2826;\n    }\n    else\n    {\n        float3 _2368 = fast::normalize(_2828);\n        float _2375 = fast::clamp(_2829, 0.0, 1.0);\n        float _2379 = fast::clamp(_2830, 0.0500000007450580596923828125, 1.0);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = fast::max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05);\n        float3 _2398 = _2826 * (1.0 - _2375);\n        float3 _2406 = mix(float3(0.039999999105930328369140625), _2826, float3(_2375));\n        float3 param_8 = _2368;\n        float3 lit = (fa_ambient_light(param_8, _416, fa_env_smp, fa_irr_tex) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _416, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _2432;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex, in.fa_world_pos);\n            float3 _2861 = _2441.direction;\n            float _2449 = fast::max(dot(_2368, _2861), 0.0);\n            float3 _2460 = fast::normalize(_2861 + _2321);\n            float _2465 = fast::max(dot(_2368, _2460), 0.0);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0)) + 1.0;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((float3(1.0) - _2406) * powr(1.0 - fast::max(dot(_2321, _2460), 0.0), 5.0))) * (((_2387 / ((3.1415927410125732421875 * _2478) * _2478)) * (0.5 / fast::max(mix((2.0 * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2449))) * fa_light_rgb(param_13, fa_light_tex, fa_shadow_smp)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        float3 param_14 = _2368;\n        float3 param_15 = _2321;\n        float3 param_16 = _2406;\n        float param_17 = _2379;\n        float3 _2547 = lit;\n        float3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17, _416, fa_env_smp, fa_env_tex) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    float3 _2552 = result;\n    float3 _2553 = _2552 + _2832;\n    result = _2553;\n    float3 param_18 = _2553;\n    float3 param_19 = in.fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19, _1156);\n    bool _2562 = _416.fa_fog.w > 0.0;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = _416.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        float3 _2579 = in.fa_world_pos - _416.fa_camera_pos.xyz;\n        float _2586 = dot(_2579, _416.fa_fog_c.xyz);\n        bool _2590 = _416.fa_fog_c.w > 0.5;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - _416.fa_fog_b.x;\n        if (_2603 > 0.0)\n        {\n            float _2612 = _416.fa_fog.w * _2603;\n            float tau = _2612 * _2612;\n            if (_416.fa_fog_b.y > 0.0)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = in.fa_world_pos.y - (_416.fa_fog_c.y * _2586);\n                }\n                else\n                {\n                    _2628 = _416.fa_camera_pos.y;\n                }\n                float _2649 = mix(_2628, in.fa_world_pos.y, fast::clamp(_416.fa_fog_b.x / _2591, 0.0, 1.0));\n                float _2653 = in.fa_world_pos.y - _2649;\n                float _2658 = _2649 - _416.fa_fog_b.z;\n                float _2663 = in.fa_world_pos.y - _416.fa_fog_b.z;\n                bool _2666 = _2658 <= 0.0;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = _416.fa_fog_b.y;\n                }\n                else\n                {\n                    _2674 = _416.fa_fog_b.y * exp(-fast::min(_416.fa_fog_b.w * _2658, 80.0));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = _416.fa_fog_b.y * _2658;\n                }\n                else\n                {\n                    _2702 = (_416.fa_fog_b.y * (1.0 - exp(-fast::min(_416.fa_fog_b.w * _2658, 80.0)))) / _416.fa_fog_b.w;\n                }\n                bool _2727 = _2663 <= 0.0;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = _416.fa_fog_b.y * _2663;\n                }\n                else\n                {\n                    _2735 = (_416.fa_fog_b.y * (1.0 - exp(-fast::min(_416.fa_fog_b.w * _2663, 80.0)))) / _416.fa_fog_b.w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * fast::max(_2762, 0.0));\n            }\n            result = mix(result, _416.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2827);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1156",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    bool _421 = _416.fa_cl_info.x < 0.0;\n    bool _428;\n    if (!_421)\n    {\n        _428 = _416.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = _416.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = _416.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = _416.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return float4(0.0);\n    }\n    float4 _460 = float4(world_pos, 1.0);\n    float _467 = dot(_416.fa_cl_vpw, _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _489 = float2(dot(_416.fa_cl_vpx, _460), dot(_416.fa_cl_vpy, _460)) / float2(_467);\n    int _493 = int(_416.fa_cl_grid.x);\n    int _497 = int(_416.fa_cl_grid.y);\n    int param = (int(_416.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_416.fa_cl_fwd.xyz, world_pos) + _416.fa_cl_fwd.w, _416.fa_cl_grid.w) / _416.fa_cl_grid.w) * _416.fa_cl_grid.z)), 0, int(_416.fa_cl_info.y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5) + 0.5) * _416.fa_cl_grid.y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5) + 0.5) * _416.fa_cl_grid.x)), 0, _493 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    float3 param = world_pos;\n    float4 _573 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _416);\n    return int2(int(_573.x), int(_573.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_416.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1971 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _416);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _188;\n    if (bool(i.front_facing))\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    float3 _212 = fast::normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    float3 _240 = fast::normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    float3 _243;\n    if (bool(i.front_facing))\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _416, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _416.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2129 = fa_tex_fix(param_2, param_3);\n    float4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    float4 _2143 = (_2974 * _416.fa_base_color) * i.vertex_color;\n    float3 _2898 = i.world_normal;\n    if (_416.fa_maps.z > 0.5)\n    {\n        float param_4 = _416.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2175 = fa_tex_fix(param_6, param_7);\n        float3 _2178 = (_2175 * 2.0) - float3(1.0);\n        float2 _2183 = _2178.xy * _416.fa_maps.x;\n        float3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _416.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2212 = fa_tex_fix(param_12, param_13);\n    float4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = _416.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2278 = fa_tex_fix(param_20, param_21);\n    return Surface{ _2143.xyz, _2143.w, _2898, fast::clamp(_416.fa_pbr.x * _2212.z, 0.0, 1.0), fast::clamp(_416.fa_pbr.y * _2212.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_416.fa_maps.y * (_2251.x - 1.0)), _416.fa_emissive.xyz + (_416.fa_model_emissive.xyz * _2278) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _2038)\n{\n    s.emission += ((tint.xyz * tint.w) * _2038.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _654 = rect.zw - rect.xy;\n    float2 _658 = _654 * atlas;\n    float2 _662 = ddx * _658;\n    float2 _666 = ddy * _658;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _654)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _701 = dfdx(world_pos);\n    float3 _704 = dfdy(world_pos);\n    bool _707 = _416.fa_counts.y < 0.5;\n    bool _714;\n    if (!_707)\n    {\n        _714 = _416.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _721 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _416);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(_416.fa_counts.y + 0.5);\n    int param_1 = _735;\n    float4 _739 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    float4 _751 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _752 = _751.x;\n    int _758 = int(_416.fa_counts.w + 0.5) - 1;\n    int _762 = int(_721.z);\n    float3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        float4 _798 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_798.w + 0.5) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        float4 _813 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _793 + 1;\n        float4 _818 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _793 + 2;\n        float4 _823 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        float3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        float3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = fast::clamp(dot(geo_normal, fast::normalize(_840)) * _798.z, 0.0, 1.0);\n        if (_881 <= 0.0)\n        {\n            continue;\n        }\n        float _901 = (fast::clamp((0.5 - abs(_845)) * 10.0, 0.0, 1.0) * _881) * _798.x;\n        float2 _909 = float2(_831 + 0.5, 0.5 - _838);\n        float2 _919 = float2(dot(_826, _701), dot(_833, _701));\n        float2 _929 = float2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        float4 _934 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _793 + 3;\n        float4 _939 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _793 + 4;\n        float4 _944 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            float4 param_11 = _939;\n            float2 param_12 = _909;\n            float2 param_13 = _742;\n            float2 param_14 = _919;\n            float2 param_15 = _929;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_752 > 0.5) && (_752 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _980 = fa_dc_to_linear(param_16);\n                float4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_901 * tex_a) * _934.w, 0.0, 1.0)));\n        if (_944.z > _944.x)\n        {\n            float4 param_17 = _944;\n            float2 param_18 = _909;\n            float2 param_19 = _742;\n            float2 param_20 = _919;\n            float2 param_21 = _929;\n            float4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_752 > 1.5)\n            {\n                float3 param_22 = _1024.xyz;\n                float3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            float3 _1044 = (_1028 * 2.0) - float3(1.0);\n            float2 _1049 = _1044.xy * _798.y;\n            float3 _1071 = (fast::normalize(_826) * _1049.x) + (fast::normalize(_833) * _1049.y);\n            float3 _1074 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1074, fast::normalize((_1074 * fast::max(_1044.z, 0.0500000007450580596923828125)) + (_1071 - (_1074 * dot(_1074, _1071)))), float3(fast::clamp(_901 * (_954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_416.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _416.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416)\n{\n    int param = (int(_416.fa_cl_info.x) + int(_416.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _416);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _288 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _294 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    float3 l;\n    if (_304)\n    {\n        l = fast::normalize(_288.xyz);\n    }\n    else\n    {\n        float3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / float3(fast::max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / fast::max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = fast::clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _353 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, fast::normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _294.xyz * atten, atten, 1.0, dist, _402 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1156)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = _1156.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = _1156.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = _1156.fa_shadow_split.z;\n            }\n            else\n            {\n                _1170 = _1156.fa_shadow_split.w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex)\n{\n    float _1208 = fast::max(_1156.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1213 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1219 = sqrt(1.0 - (_1213 * _1213));\n    float _1226 = fast::min(_1219 / fast::max(_1213, 0.20000000298023223876953125), 4.0);\n    float _1231;\n    if (_1156.fa_shadow_bias.y > 0.0)\n    {\n        _1231 = _1156.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1231 = 1.5 * _1156.fa_shadow_info[ci].x;\n    }\n    float4 _1256 = _1156.fa_shadow_mat[ci] * float4(world + (n * (_1231 * _1219)), 1.0);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < _1156.fa_shadow_rect[ci].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > _1156.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < _1156.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > _1156.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0;\n    }\n    float _1309;\n    if (_1156.fa_shadow_bias.x > 0.0)\n    {\n        _1309 = _1156.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1309 = 1.5 * _1156.fa_shadow_info[ci].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0 + (0.5 * _1226))) / _1208);\n    float _1337 = ((_1156.fa_shadow_info[ci].x * fast::min(_1226, 3.0)) * 0.5) / _1208;\n    int _1346 = int(_1156.fa_shadow_cfg.z + 0.5);\n    if (_1346 == 1)\n    {\n        float2 param = _1256.xy;\n        float4 param_1 = _1156.fa_shadow_rect[ci];\n        float _1357 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = fast::clamp(((_1156.fa_shadow_cfg.w * _1208) * 0.25) / _1156.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            float2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            float2 param_5 = _1256.xy + (_1400 * _1156.fa_shadow_bias.zw);\n            float4 param_6 = _1156.fa_shadow_rect[ci];\n            float _1411 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1328 - (sum / cnt), 0.0) * _1208) * _1156.fa_shadow_cfg.w) / _1156.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        float2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1256.xy + (_1474 * _1156.fa_shadow_bias.zw);\n        float4 param_11 = _1156.fa_shadow_rect[ci];\n        float _1485 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex)\n{\n    if (_416.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1515 = int(_1156.fa_shadow_cfg.x + 0.5);\n    if (_1515 < 1)\n    {\n        return 1.0;\n    }\n    float _1530 = dot(world - _1156.fa_shadow_eye.xyz, _1156.fa_shadow_fwd.xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param, _1156))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > _1156.fa_shadow_split.x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > _1156.fa_shadow_split.y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > _1156.fa_shadow_split.z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1156, fa_shadow_tex);\n        s = _1597;\n        if (_1597 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1156.fa_shadow_cfg.y > 0.0)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5, _1156);\n        }\n        else\n        {\n            _1622 = _1156.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1641 = _1156.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1156) - _1622, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1652 = fast::clamp((_1530 - (fa_shadow_split_at(param_7, _1156) - _1641)) / _1641, 0.0, 1.0);\n        if (_1652 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1156, fa_shadow_tex);\n                s2 = _1673;\n                if (_1673 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _416, thread float4& gl_FragCoord, constant fa_shadows& _1156, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2883 = _1999.direction;\n    float3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex, fa_world_pos);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    return LightSample{ _2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1903 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1906 = _1903.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1906 * _1906, exp2((-9.27999973297119140625) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_416.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _416.fa_env_horizon.w)).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625 * _1809;\n    return mix(mix(_416.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_416.fa_env_horizon.xyz, _416.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1809)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1839, 0.0500000007450580596923828125 + _1839, d.y))), ((_416.fa_env_sky.xyz + _416.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1809 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _416, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1945 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _416, fa_env_smp, fa_env_tex) * ((f0 * _1945.x) + float3(_1945.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1156)\n{\n    if (_1156.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1697 = int(_1156.fa_shadow_cfg.x + 0.5);\n    float _1707 = dot(world - _1156.fa_shadow_eye.xyz, _1156.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param, _1156);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > _1156.fa_shadow_split.x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > _1156.fa_shadow_split.y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > _1156.fa_shadow_split.z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _416 [[buffer(1)]], constant fa_material& _2038 [[buffer(5)]], constant fa_shadows& _1156 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2803 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    float3 _2321 = fast::normalize(_416.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _416, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2803, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2321, short(gl_FrontFacing) };\n    Surface _2329 = fa_standard_surface(param_1, _416, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    float3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    float3 _2832 = _2329.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2803, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2321, short(gl_FrontFacing) };\n    Surface param_3 = _2329;\n    surface(param_2, param_3, tint, _2038);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2803;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _416, fa_decal_tex, fa_env_smp);\n    _2826 = param_6;\n    _2828 = param_7;\n    float3 result;\n    if (_416.fa_emissive.w > 0.5)\n    {\n        result = _2826;\n    }\n    else\n    {\n        float3 _2368 = fast::normalize(_2828);\n        float _2375 = fast::clamp(_2829, 0.0, 1.0);\n        float _2379 = fast::clamp(_2830, 0.0500000007450580596923828125, 1.0);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = fast::max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05);\n        float3 _2398 = _2826 * (1.0 - _2375);\n        float3 _2406 = mix(float3(0.039999999105930328369140625), _2826, float3(_2375));\n        float3 param_8 = _2368;\n        float3 lit = (fa_ambient_light(param_8, _416, fa_env_smp, fa_irr_tex) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _416, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _2432;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _416, gl_FragCoord, _1156, fa_shadow_tex, in.fa_world_pos);\n            float3 _2861 = _2441.direction;\n            float _2449 = fast::max(dot(_2368, _2861), 0.0);\n            float3 _2460 = fast::normalize(_2861 + _2321);\n            float _2465 = fast::max(dot(_2368, _2460), 0.0);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0)) + 1.0;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((float3(1.0) - _2406) * powr(1.0 - fast::max(dot(_2321, _2460), 0.0), 5.0))) * (((_2387 / ((3.1415927410125732421875 * _2478) * _2478)) * (0.5 / fast::max(mix((2.0 * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2449))) * fa_light_rgb(param_13, fa_light_tex, fa_shadow_smp)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        float3 param_14 = _2368;\n        float3 param_15 = _2321;\n        float3 param_16 = _2406;\n        float param_17 = _2379;\n        float3 _2547 = lit;\n        float3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17, _416, fa_env_smp, fa_env_tex) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    float3 _2552 = result;\n    float3 _2553 = _2552 + _2832;\n    result = _2553;\n    float3 param_18 = _2553;\n    float3 param_19 = in.fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19, _1156);\n    bool _2562 = _416.fa_fog.w > 0.0;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = _416.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        float3 _2579 = in.fa_world_pos - _416.fa_camera_pos.xyz;\n        float _2586 = dot(_2579, _416.fa_fog_c.xyz);\n        bool _2590 = _416.fa_fog_c.w > 0.5;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - _416.fa_fog_b.x;\n        if (_2603 > 0.0)\n        {\n            float _2612 = _416.fa_fog.w * _2603;\n            float tau = _2612 * _2612;\n            if (_416.fa_fog_b.y > 0.0)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = in.fa_world_pos.y - (_416.fa_fog_c.y * _2586);\n                }\n                else\n                {\n                    _2628 = _416.fa_camera_pos.y;\n                }\n                float _2649 = mix(_2628, in.fa_world_pos.y, fast::clamp(_416.fa_fog_b.x / _2591, 0.0, 1.0));\n                float _2653 = in.fa_world_pos.y - _2649;\n                float _2658 = _2649 - _416.fa_fog_b.z;\n                float _2663 = in.fa_world_pos.y - _416.fa_fog_b.z;\n                bool _2666 = _2658 <= 0.0;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = _416.fa_fog_b.y;\n                }\n                else\n                {\n                    _2674 = _416.fa_fog_b.y * exp(-fast::min(_416.fa_fog_b.w * _2658, 80.0));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = _416.fa_fog_b.y * _2658;\n                }\n                else\n                {\n                    _2702 = (_416.fa_fog_b.y * (1.0 - exp(-fast::min(_416.fa_fog_b.w * _2658, 80.0)))) / _416.fa_fog_b.w;\n                }\n                bool _2727 = _2663 <= 0.0;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = _416.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = _416.fa_fog_b.y * _2663;\n                }\n                else\n                {\n                    _2735 = (_416.fa_fog_b.y * (1.0 - exp(-fast::min(_416.fa_fog_b.w * _2663, 80.0)))) / _416.fa_fog_b.w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * fast::max(_2762, 0.0));\n            }\n            result = mix(result, _416.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2827);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1156",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    float4 _280 = (_625 * _253.fa_base_color) * i.vertex_color;\n    float3 _606 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _606, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _553 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _553, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _553, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    float4 _310 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_158.fa_light_vp * _310).z;\n    fa_pre_r0 = float3(_158.fa_light_vp[0].x, _158.fa_light_vp[1].x, _158.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158.fa_light_vp[0].y, _158.fa_light_vp[1].y, _158.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158.fa_light_vp[0].z, _158.fa_light_vp[1].z, _158.fa_light_vp[2].z);\n    gl_Position = _158.fa_view_proj * _310;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    float4 _280 = (_625 * _253.fa_base_color) * i.vertex_color;\n    float3 _606 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _606, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _553 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _553, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _553, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, raise);\n    out.gl_Position = _144.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_144",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _196)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_196.fa_joint_rows[_187] * weights[i]);\n        r1 += (_196.fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196.fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _196 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _196);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _149);\n    vertex0(param_8, raise);\n    out.gl_Position = _149.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_149",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
