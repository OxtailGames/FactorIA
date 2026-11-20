{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391)\n{\n    bool _396 = _391.fa_cl_info.x < 0.0;\n    bool _403;\n    if (!_396)\n    {\n        _403 = _391.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    bool _411;\n    if (!_403)\n    {\n        _411 = _391.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _411 = _403;\n    }\n    bool _418;\n    if (!_411)\n    {\n        _418 = _391.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = _391.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    if (_425)\n    {\n        return int2(0);\n    }\n    float4 _435 = float4(world_pos, 1.0);\n    float _442 = dot(_391.fa_cl_vpw, _435);\n    if (!(_442 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _464 = float2(dot(_391.fa_cl_vpx, _435), dot(_391.fa_cl_vpy, _435)) / float2(_442);\n    int _468 = int(_391.fa_cl_grid.x);\n    int _472 = int(_391.fa_cl_grid.y);\n    int param = (int(_391.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_391.fa_cl_fwd.xyz, world_pos) + _391.fa_cl_fwd.w, _391.fa_cl_grid.w) / _391.fa_cl_grid.w) * _391.fa_cl_grid.z)), 0, int(_391.fa_cl_info.y) - 1) * _472) + clamp(int(floor(((_464.y * 0.5) + 0.5) * _391.fa_cl_grid.y)), 0, _472 - 1)) * _468)) + clamp(int(floor(((_464.x * 0.5) + 0.5) * _391.fa_cl_grid.x)), 0, _468 - 1);\n    float4 _543 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_543.x), int(_543.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_391.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1446 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _391);\n    fa_cl_slot = _1446.x;\n    fa_cl_local = _1446.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1578 = fa_linear_to_srgb(param);\n        c = _1578;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1586 = fa_srgb_to_linear(param_1);\n            c = _1586;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _163;\n    if (bool(i.front_facing))\n    {\n        _163 = i.world_normal;\n    }\n    else\n    {\n        _163 = -i.world_normal;\n    }\n    float3 _187 = fast::normalize(i.world_tangent.xyz - (_163 * dot(_163, i.world_tangent.xyz)));\n    float3 _215 = fast::normalize(((_187 * m.x) + ((cross(_163, _187) * i.world_tangent.w) * m.y)) + (_163 * m.z));\n    float3 _218;\n    if (bool(i.front_facing))\n    {\n        _218 = _215;\n    }\n    else\n    {\n        _218 = -_215;\n    }\n    return _218;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _391, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _391.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1617 = fa_tex_fix(param_2, param_3);\n    float4 _2411 = base_t;\n    _2411.x = _1617.x;\n    _2411.y = _1617.y;\n    _2411.z = _1617.z;\n    base_t = _2411;\n    float4 _1631 = (_2411 * _391.fa_base_color) * i.vertex_color;\n    float3 _2370 = i.world_normal;\n    if (_391.fa_maps.z > 0.5)\n    {\n        float param_4 = _391.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1663 = fa_tex_fix(param_6, param_7);\n        float3 _1667 = (_1663 * 2.0) - float3(1.0);\n        float2 _1672 = _1667.xy * _391.fa_maps.x;\n        float3 _2419 = _1667;\n        _2419.x = _1672.x;\n        _2419.y = _1672.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2419;\n        _2370 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _391.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1701 = fa_tex_fix(param_12, param_13);\n    float4 _2422 = mrt;\n    _2422.x = _1701.x;\n    _2422.y = _1701.y;\n    _2422.z = _1701.z;\n    mrt = _2422;\n    float param_14 = _391.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1740 = fa_tex_fix(param_16, param_17);\n    float param_18 = _391.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1767 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1631.xyz, _1631.w, _2370, fast::clamp(_391.fa_pbr.x * _1701.z, 0.0, 1.0), fast::clamp(_391.fa_pbr.y * _1701.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_391.fa_maps.y * (_1740.x - 1.0)), _391.fa_emissive.xyz + (_391.fa_model_emissive.xyz * _1767) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _1513)\n{\n    s.emission += ((tint.xyz * tint.w) * _1513.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _391, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_391.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _391.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391)\n{\n    int param = (int(_391.fa_cl_info.x) + int(_391.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _391);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _263 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _269 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _272 = _269.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _279 = _272 < 0.5;\n    float3 l;\n    if (_279)\n    {\n        l = fast::normalize(_263.xyz);\n    }\n    else\n    {\n        float3 _291 = _263.xyz - world_pos;\n        float _293 = length(_291);\n        dist = _293;\n        l = _291 / float3(fast::max(_293, 9.9999997473787516355514526367188e-05));\n        float _308 = _293 / fast::max(_263.w, 0.001000000047497451305389404296875);\n        float _314 = fast::clamp(1.0 - (_308 * _308), 0.0, 1.0);\n        atten = _314 * _314;\n        if (_272 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _328 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _338 = _328.w;\n            int param_3 = (li * 4) + 3;\n            float4 _345 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _346 = _345.x;\n            float cos_inner = _346;\n            if (_346 > 1.5)\n            {\n                cos_inner = mix(_338, 1.0, 0.25);\n            }\n            atten *= smoothstep(_338, cos_inner, dot(-l, fast::normalize(_328.xyz)));\n        }\n    }\n    int _377;\n    if (_279)\n    {\n        _377 = 0;\n    }\n    else\n    {\n        _377 = (_272 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _269.xyz * atten, atten, 1.0, dist, _377 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _627)\n{\n    float _617;\n    if (i == 0)\n    {\n        _617 = _627.fa_shadow_split.x;\n    }\n    else\n    {\n        float _633;\n        if (i == 1)\n        {\n            _633 = _627.fa_shadow_split.y;\n        }\n        else\n        {\n            float _641;\n            if (i == 2)\n            {\n                _641 = _627.fa_shadow_split.z;\n            }\n            else\n            {\n                _641 = _627.fa_shadow_split.w;\n            }\n            _633 = _641;\n        }\n        _617 = _633;\n    }\n    return _617;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _605 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_605), sin(_605)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex)\n{\n    float _679 = fast::max(_627.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _684 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _690 = sqrt(1.0 - (_684 * _684));\n    float _698 = fast::min(_690 / fast::max(_684, 0.20000000298023223876953125), 4.0);\n    float _703;\n    if (_627.fa_shadow_bias.y > 0.0)\n    {\n        _703 = _627.fa_shadow_bias.y;\n    }\n    else\n    {\n        _703 = 1.5 * _627.fa_shadow_info[ci].x;\n    }\n    float4 _728 = _627.fa_shadow_mat[ci] * float4(world + (n * (_703 * _690)), 1.0);\n    float _735 = _728.x;\n    bool _738 = _735 < _627.fa_shadow_rect[ci].x;\n    bool _747;\n    if (!_738)\n    {\n        _747 = _735 > _627.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _747 = _738;\n    }\n    bool _756;\n    if (!_747)\n    {\n        _756 = _728.y < _627.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _756 = _747;\n    }\n    bool _765;\n    if (!_756)\n    {\n        _765 = _728.y > _627.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _765 = _756;\n    }\n    bool _772;\n    if (!_765)\n    {\n        _772 = _728.z > 1.0;\n    }\n    else\n    {\n        _772 = _765;\n    }\n    if (_772)\n    {\n        return -1.0;\n    }\n    float _781;\n    if (_627.fa_shadow_bias.x > 0.0)\n    {\n        _781 = _627.fa_shadow_bias.x;\n    }\n    else\n    {\n        _781 = 1.5 * _627.fa_shadow_info[ci].x;\n    }\n    float _800 = _728.z - ((_781 * (1.0 + (0.5 * _698))) / _679);\n    float _809 = ((_627.fa_shadow_info[ci].x * fast::min(_698, 3.0)) * 0.5) / _679;\n    int _818 = int(_627.fa_shadow_cfg.z + 0.5);\n    if (_818 == 1)\n    {\n        float2 param = _728.xy;\n        float4 param_1 = _627.fa_shadow_rect[ci];\n        float _829 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_800 <= _829);\n    }\n    float _836 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _839 = _818 == 2;\n    if (_839)\n    {\n        float _853 = fast::clamp(((_627.fa_shadow_cfg.w * _679) * 0.25) / _627.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _836;\n            float2 _872 = fa_shadow_vogel(param_2, param_3, param_4) * _853;\n            float2 param_5 = _728.xy + (_872 * _627.fa_shadow_bias.zw);\n            float4 param_6 = _627.fa_shadow_rect[ci];\n            float _883 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_883 < (_800 - (length(_872) * _809)))\n            {\n                sum += _883;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_800 - (sum / cnt), 0.0) * _679) * _627.fa_shadow_cfg.w) / _627.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _927 = _839 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _927; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _927;\n        float param_9 = _836;\n        float2 _946 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _728.xy + (_946 * _627.fa_shadow_bias.zw);\n        float4 param_11 = _627.fa_shadow_rect[ci];\n        float _957 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_800 - (length(_946) * _809)) <= _957);\n    }\n    return lit / float(_927);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex)\n{\n    if (_391.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _987 = int(_627.fa_shadow_cfg.x + 0.5);\n    if (_987 < 1)\n    {\n        return 1.0;\n    }\n    float _1003 = dot(world - _627.fa_shadow_eye.xyz, _627.fa_shadow_fwd.xyz);\n    int param = _987 - 1;\n    if (_1003 > fa_shadow_split_at(param, _627))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1015 = _987 > 1;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _1003 > _627.fa_shadow_split.x;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 1;\n    }\n    bool _1026 = _987 > 2;\n    bool _1033;\n    if (_1026)\n    {\n        _1033 = _1003 > _627.fa_shadow_split.y;\n    }\n    else\n    {\n        _1033 = _1026;\n    }\n    if (_1033)\n    {\n        ci = 2;\n    }\n    bool _1037 = _987 > 3;\n    bool _1044;\n    if (_1037)\n    {\n        _1044 = _1003 > _627.fa_shadow_split.z;\n    }\n    else\n    {\n        _1044 = _1037;\n    }\n    if (_1044)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1070 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _627, fa_shadow_tex);\n        s = _1070;\n        if (_1070 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_627.fa_shadow_cfg.y > 0.0)\n    {\n        float _1095;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1095 = fa_shadow_split_at(param_5, _627);\n        }\n        else\n        {\n            _1095 = _627.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1114 = _627.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _627) - _1095, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1125 = fast::clamp((_1003 - (fa_shadow_split_at(param_7, _627) - _1114)) / _1114, 0.0, 1.0);\n        if (_1125 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _987)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1146 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _627, fa_shadow_tex);\n                s2 = _1146;\n                if (_1146 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1125);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1474 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2355 = _1474.direction;\n    float3 _2350 = _1474.color;\n    float _2352 = _1474.shadow;\n    int _2360 = _1474.type;\n    if ((_2360 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2355;\n        float _1488 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex, fa_world_pos);\n        _2352 = _1488;\n        _2350 *= _1488;\n    }\n    return LightSample{ _2355, _2350, _1474.attenuation, _2352, _1474._distance, _2360 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1378 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1381 = _1378.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1381 * _1381, exp2((-9.27999973297119140625) * ndv)) * _1381) + _1378.y)) + _1378.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _391, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_391.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _391.fa_env_horizon.w)).xyz;\n    }\n    float _1283 = rough * rough;\n    float _1313 = 0.60000002384185791015625 * _1283;\n    return mix(mix(_391.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_391.fa_env_horizon.xyz, _391.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1283)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1313, 0.0500000007450580596923828125 + _1313, d.y))), ((_391.fa_env_sky.xyz + _391.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1283 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _391, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1420 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _391, fa_env_tex, fa_env_smp) * ((f0 * _1420.x) + float3(_1420.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _627)\n{\n    if (_627.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1170 = int(_627.fa_shadow_cfg.x + 0.5);\n    float _1180 = dot(world - _627.fa_shadow_eye.xyz, _627.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1185 = _1170 > 0;\n    bool _1194;\n    if (_1185)\n    {\n        int param = _1170 - 1;\n        _1194 = _1180 <= fa_shadow_split_at(param, _627);\n    }\n    else\n    {\n        _1194 = _1185;\n    }\n    if (_1194)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1201 = _1170 > 1;\n        bool _1208;\n        if (_1201)\n        {\n            _1208 = _1180 > _627.fa_shadow_split.x;\n        }\n        else\n        {\n            _1208 = _1201;\n        }\n        if (_1208)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1214 = _1170 > 2;\n        bool _1221;\n        if (_1214)\n        {\n            _1221 = _1180 > _627.fa_shadow_split.y;\n        }\n        else\n        {\n            _1221 = _1214;\n        }\n        if (_1221)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1227 = _1170 > 3;\n        bool _1234;\n        if (_1227)\n        {\n            _1234 = _1180 > _627.fa_shadow_split.z;\n        }\n        else\n        {\n            _1234 = _1227;\n        }\n        if (_1234)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _391 [[buffer(1)]], constant fa_material& _1513 [[buffer(5)]], constant fa_shadows& _627 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2275 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2275 = -_2275;\n    }\n    float3 _1810 = fast::normalize(_391.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _391, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2275, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1810, short(gl_FrontFacing) };\n    Surface _1818 = fa_standard_surface(param_1, _391, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2298 = _1818.albedo;\n    float _2299 = _1818.alpha;\n    float3 _2300 = _1818.normal;\n    float _2301 = _1818.metallic;\n    float _2302 = _1818.roughness;\n    float _2303 = _1818.occlusion;\n    float3 _2304 = _1818.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2275, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1810, short(gl_FrontFacing) };\n    Surface param_3 = _1818;\n    surface(param_2, param_3, tint, _1513);\n    _2298 = param_3.albedo;\n    _2299 = param_3.alpha;\n    _2300 = param_3.normal;\n    _2301 = param_3.metallic;\n    _2302 = param_3.roughness;\n    _2303 = param_3.occlusion;\n    _2304 = param_3.emission;\n    float3 result;\n    if (_391.fa_emissive.w > 0.5)\n    {\n        result = _2298;\n    }\n    else\n    {\n        float3 _1840 = fast::normalize(_2300);\n        float _1847 = fast::clamp(_2301, 0.0, 1.0);\n        float _1851 = fast::clamp(_2302, 0.0500000007450580596923828125, 1.0);\n        float _1855 = _1851 * _1851;\n        float _1859 = _1855 * _1855;\n        float _1864 = fast::max(dot(_1840, _1810), 9.9999997473787516355514526367188e-05);\n        float3 _1870 = _2298 * (1.0 - _1847);\n        float3 _1878 = mix(float3(0.039999999105930328369140625), _2298, float3(_1847));\n        float3 param_4 = _1840;\n        float3 lit = (fa_ambient_light(param_4, _391, fa_env_smp, fa_irr_tex) * _1870) * _2303;\n        int _1891 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1891; ln++)\n        {\n            int param_5 = ln;\n            int _1904 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _391, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1904;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2275;\n            LightSample _1913 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex, in.fa_world_pos);\n            float3 _2333 = _1913.direction;\n            float _1921 = fast::max(dot(_1840, _2333), 0.0);\n            float3 _1932 = fast::normalize(_2333 + _1810);\n            float _1937 = fast::max(dot(_1840, _1932), 0.0);\n            float _1950 = ((_1937 * _1937) * (_1859 - 1.0)) + 1.0;\n            int param_9 = _1904;\n            lit += (((_1870 + (((_1878 + ((float3(1.0) - _1878) * powr(1.0 - fast::max(dot(_1810, _1932), 0.0), 5.0))) * (((_1859 / ((3.1415927410125732421875 * _1950) * _1950)) * (0.5 / fast::max(mix((2.0 * _1921) * _1864, _1921 + _1864, _1855), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1921))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1921 * (_1913.attenuation * _1913.shadow)));\n        }\n        float3 param_10 = _1840;\n        float3 param_11 = _1810;\n        float3 param_12 = _1878;\n        float param_13 = _1851;\n        float3 _2019 = lit;\n        float3 _2020 = _2019 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _391, fa_env_tex, fa_env_smp) * _2303);\n        lit = _2020;\n        result = _2020;\n    }\n    float3 _2024 = result;\n    float3 _2025 = _2024 + _2304;\n    result = _2025;\n    float3 param_14 = _2025;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _627);\n    bool _2034 = _391.fa_fog.w > 0.0;\n    bool _2042;\n    if (!_2034)\n    {\n        _2042 = _391.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2042 = _2034;\n    }\n    if (_2042)\n    {\n        float3 _2051 = in.fa_world_pos - _391.fa_camera_pos.xyz;\n        float _2058 = dot(_2051, _391.fa_fog_c.xyz);\n        bool _2062 = _391.fa_fog_c.w > 0.5;\n        float _2063;\n        if (_2062)\n        {\n            _2063 = _2058;\n        }\n        else\n        {\n            _2063 = length(_2051);\n        }\n        float _2075 = _2063 - _391.fa_fog_b.x;\n        if (_2075 > 0.0)\n        {\n            float _2084 = _391.fa_fog.w * _2075;\n            float tau = _2084 * _2084;\n            if (_391.fa_fog_b.y > 0.0)\n            {\n                float _2100;\n                if (_2062)\n                {\n                    _2100 = in.fa_world_pos.y - (_391.fa_fog_c.y * _2058);\n                }\n                else\n                {\n                    _2100 = _391.fa_camera_pos.y;\n                }\n                float _2121 = mix(_2100, in.fa_world_pos.y, fast::clamp(_391.fa_fog_b.x / _2063, 0.0, 1.0));\n                float _2125 = in.fa_world_pos.y - _2121;\n                float _2130 = _2121 - _391.fa_fog_b.z;\n                float _2135 = in.fa_world_pos.y - _391.fa_fog_b.z;\n                bool _2138 = _2130 <= 0.0;\n                bool _2139 = !_2138;\n                bool _2145;\n                if (_2139)\n                {\n                    _2145 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2138;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _391.fa_fog_b.y;\n                }\n                else\n                {\n                    _2146 = _391.fa_fog_b.y * exp(-fast::min(_391.fa_fog_b.w * _2130, 80.0));\n                }\n                bool _2173;\n                if (_2139)\n                {\n                    _2173 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2173 = _2138;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = _391.fa_fog_b.y * _2130;\n                }\n                else\n                {\n                    _2174 = (_391.fa_fog_b.y * (1.0 - exp(-fast::min(_391.fa_fog_b.w * _2130, 80.0)))) / _391.fa_fog_b.w;\n                }\n                bool _2199 = _2135 <= 0.0;\n                bool _2206;\n                if (!_2199)\n                {\n                    _2206 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2206 = _2199;\n                }\n                float _2207;\n                if (_2206)\n                {\n                    _2207 = _391.fa_fog_b.y * _2135;\n                }\n                else\n                {\n                    _2207 = (_391.fa_fog_b.y * (1.0 - exp(-fast::min(_391.fa_fog_b.w * _2135, 80.0)))) / _391.fa_fog_b.w;\n                }\n                float _2234;\n                if (abs(_2125) < 0.001000000047497451305389404296875)\n                {\n                    _2234 = _2146;\n                }\n                else\n                {\n                    _2234 = (_2207 - _2174) / _2125;\n                }\n                tau += (_2075 * fast::max(_2234, 0.0));\n            }\n            result = mix(result, _391.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2299);\n    return out;\n}\n\n",
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
            "inst_name": "_391",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_627",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1513",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391)\n{\n    bool _396 = _391.fa_cl_info.x < 0.0;\n    bool _403;\n    if (!_396)\n    {\n        _403 = _391.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    bool _411;\n    if (!_403)\n    {\n        _411 = _391.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _411 = _403;\n    }\n    bool _418;\n    if (!_411)\n    {\n        _418 = _391.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = _391.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    if (_425)\n    {\n        return int2(0);\n    }\n    float4 _435 = float4(world_pos, 1.0);\n    float _442 = dot(_391.fa_cl_vpw, _435);\n    if (!(_442 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _464 = float2(dot(_391.fa_cl_vpx, _435), dot(_391.fa_cl_vpy, _435)) / float2(_442);\n    int _468 = int(_391.fa_cl_grid.x);\n    int _472 = int(_391.fa_cl_grid.y);\n    int param = (int(_391.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_391.fa_cl_fwd.xyz, world_pos) + _391.fa_cl_fwd.w, _391.fa_cl_grid.w) / _391.fa_cl_grid.w) * _391.fa_cl_grid.z)), 0, int(_391.fa_cl_info.y) - 1) * _472) + clamp(int(floor(((_464.y * 0.5) + 0.5) * _391.fa_cl_grid.y)), 0, _472 - 1)) * _468)) + clamp(int(floor(((_464.x * 0.5) + 0.5) * _391.fa_cl_grid.x)), 0, _468 - 1);\n    float4 _543 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_543.x), int(_543.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_391.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1446 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _391);\n    fa_cl_slot = _1446.x;\n    fa_cl_local = _1446.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1578 = fa_linear_to_srgb(param);\n        c = _1578;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1586 = fa_srgb_to_linear(param_1);\n            c = _1586;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _163;\n    if (bool(i.front_facing))\n    {\n        _163 = i.world_normal;\n    }\n    else\n    {\n        _163 = -i.world_normal;\n    }\n    float3 _187 = fast::normalize(i.world_tangent.xyz - (_163 * dot(_163, i.world_tangent.xyz)));\n    float3 _215 = fast::normalize(((_187 * m.x) + ((cross(_163, _187) * i.world_tangent.w) * m.y)) + (_163 * m.z));\n    float3 _218;\n    if (bool(i.front_facing))\n    {\n        _218 = _215;\n    }\n    else\n    {\n        _218 = -_215;\n    }\n    return _218;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _391, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _391.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1617 = fa_tex_fix(param_2, param_3);\n    float4 _2411 = base_t;\n    _2411.x = _1617.x;\n    _2411.y = _1617.y;\n    _2411.z = _1617.z;\n    base_t = _2411;\n    float4 _1631 = (_2411 * _391.fa_base_color) * i.vertex_color;\n    float3 _2370 = i.world_normal;\n    if (_391.fa_maps.z > 0.5)\n    {\n        float param_4 = _391.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1663 = fa_tex_fix(param_6, param_7);\n        float3 _1667 = (_1663 * 2.0) - float3(1.0);\n        float2 _1672 = _1667.xy * _391.fa_maps.x;\n        float3 _2419 = _1667;\n        _2419.x = _1672.x;\n        _2419.y = _1672.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2419;\n        _2370 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _391.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1701 = fa_tex_fix(param_12, param_13);\n    float4 _2422 = mrt;\n    _2422.x = _1701.x;\n    _2422.y = _1701.y;\n    _2422.z = _1701.z;\n    mrt = _2422;\n    float param_14 = _391.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1740 = fa_tex_fix(param_16, param_17);\n    float param_18 = _391.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1767 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1631.xyz, _1631.w, _2370, fast::clamp(_391.fa_pbr.x * _1701.z, 0.0, 1.0), fast::clamp(_391.fa_pbr.y * _1701.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_391.fa_maps.y * (_1740.x - 1.0)), _391.fa_emissive.xyz + (_391.fa_model_emissive.xyz * _1767) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _1513)\n{\n    s.emission += ((tint.xyz * tint.w) * _1513.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _391, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_391.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _391.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391)\n{\n    int param = (int(_391.fa_cl_info.x) + int(_391.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _391);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _263 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _269 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _272 = _269.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _279 = _272 < 0.5;\n    float3 l;\n    if (_279)\n    {\n        l = fast::normalize(_263.xyz);\n    }\n    else\n    {\n        float3 _291 = _263.xyz - world_pos;\n        float _293 = length(_291);\n        dist = _293;\n        l = _291 / float3(fast::max(_293, 9.9999997473787516355514526367188e-05));\n        float _308 = _293 / fast::max(_263.w, 0.001000000047497451305389404296875);\n        float _314 = fast::clamp(1.0 - (_308 * _308), 0.0, 1.0);\n        atten = _314 * _314;\n        if (_272 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _328 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _338 = _328.w;\n            int param_3 = (li * 4) + 3;\n            float4 _345 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _346 = _345.x;\n            float cos_inner = _346;\n            if (_346 > 1.5)\n            {\n                cos_inner = mix(_338, 1.0, 0.25);\n            }\n            atten *= smoothstep(_338, cos_inner, dot(-l, fast::normalize(_328.xyz)));\n        }\n    }\n    int _377;\n    if (_279)\n    {\n        _377 = 0;\n    }\n    else\n    {\n        _377 = (_272 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _269.xyz * atten, atten, 1.0, dist, _377 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _627)\n{\n    float _617;\n    if (i == 0)\n    {\n        _617 = _627.fa_shadow_split.x;\n    }\n    else\n    {\n        float _633;\n        if (i == 1)\n        {\n            _633 = _627.fa_shadow_split.y;\n        }\n        else\n        {\n            float _641;\n            if (i == 2)\n            {\n                _641 = _627.fa_shadow_split.z;\n            }\n            else\n            {\n                _641 = _627.fa_shadow_split.w;\n            }\n            _633 = _641;\n        }\n        _617 = _633;\n    }\n    return _617;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _605 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_605), sin(_605)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex)\n{\n    float _679 = fast::max(_627.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _684 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _690 = sqrt(1.0 - (_684 * _684));\n    float _698 = fast::min(_690 / fast::max(_684, 0.20000000298023223876953125), 4.0);\n    float _703;\n    if (_627.fa_shadow_bias.y > 0.0)\n    {\n        _703 = _627.fa_shadow_bias.y;\n    }\n    else\n    {\n        _703 = 1.5 * _627.fa_shadow_info[ci].x;\n    }\n    float4 _728 = _627.fa_shadow_mat[ci] * float4(world + (n * (_703 * _690)), 1.0);\n    float _735 = _728.x;\n    bool _738 = _735 < _627.fa_shadow_rect[ci].x;\n    bool _747;\n    if (!_738)\n    {\n        _747 = _735 > _627.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _747 = _738;\n    }\n    bool _756;\n    if (!_747)\n    {\n        _756 = _728.y < _627.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _756 = _747;\n    }\n    bool _765;\n    if (!_756)\n    {\n        _765 = _728.y > _627.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _765 = _756;\n    }\n    bool _772;\n    if (!_765)\n    {\n        _772 = _728.z > 1.0;\n    }\n    else\n    {\n        _772 = _765;\n    }\n    if (_772)\n    {\n        return -1.0;\n    }\n    float _781;\n    if (_627.fa_shadow_bias.x > 0.0)\n    {\n        _781 = _627.fa_shadow_bias.x;\n    }\n    else\n    {\n        _781 = 1.5 * _627.fa_shadow_info[ci].x;\n    }\n    float _800 = _728.z - ((_781 * (1.0 + (0.5 * _698))) / _679);\n    float _809 = ((_627.fa_shadow_info[ci].x * fast::min(_698, 3.0)) * 0.5) / _679;\n    int _818 = int(_627.fa_shadow_cfg.z + 0.5);\n    if (_818 == 1)\n    {\n        float2 param = _728.xy;\n        float4 param_1 = _627.fa_shadow_rect[ci];\n        float _829 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_800 <= _829);\n    }\n    float _836 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _839 = _818 == 2;\n    if (_839)\n    {\n        float _853 = fast::clamp(((_627.fa_shadow_cfg.w * _679) * 0.25) / _627.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _836;\n            float2 _872 = fa_shadow_vogel(param_2, param_3, param_4) * _853;\n            float2 param_5 = _728.xy + (_872 * _627.fa_shadow_bias.zw);\n            float4 param_6 = _627.fa_shadow_rect[ci];\n            float _883 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_883 < (_800 - (length(_872) * _809)))\n            {\n                sum += _883;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_800 - (sum / cnt), 0.0) * _679) * _627.fa_shadow_cfg.w) / _627.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _927 = _839 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _927; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _927;\n        float param_9 = _836;\n        float2 _946 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _728.xy + (_946 * _627.fa_shadow_bias.zw);\n        float4 param_11 = _627.fa_shadow_rect[ci];\n        float _957 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_800 - (length(_946) * _809)) <= _957);\n    }\n    return lit / float(_927);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex)\n{\n    if (_391.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _987 = int(_627.fa_shadow_cfg.x + 0.5);\n    if (_987 < 1)\n    {\n        return 1.0;\n    }\n    float _1003 = dot(world - _627.fa_shadow_eye.xyz, _627.fa_shadow_fwd.xyz);\n    int param = _987 - 1;\n    if (_1003 > fa_shadow_split_at(param, _627))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1015 = _987 > 1;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _1003 > _627.fa_shadow_split.x;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 1;\n    }\n    bool _1026 = _987 > 2;\n    bool _1033;\n    if (_1026)\n    {\n        _1033 = _1003 > _627.fa_shadow_split.y;\n    }\n    else\n    {\n        _1033 = _1026;\n    }\n    if (_1033)\n    {\n        ci = 2;\n    }\n    bool _1037 = _987 > 3;\n    bool _1044;\n    if (_1037)\n    {\n        _1044 = _1003 > _627.fa_shadow_split.z;\n    }\n    else\n    {\n        _1044 = _1037;\n    }\n    if (_1044)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1070 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _627, fa_shadow_tex);\n        s = _1070;\n        if (_1070 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_627.fa_shadow_cfg.y > 0.0)\n    {\n        float _1095;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1095 = fa_shadow_split_at(param_5, _627);\n        }\n        else\n        {\n            _1095 = _627.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1114 = _627.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _627) - _1095, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1125 = fast::clamp((_1003 - (fa_shadow_split_at(param_7, _627) - _1114)) / _1114, 0.0, 1.0);\n        if (_1125 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _987)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1146 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _627, fa_shadow_tex);\n                s2 = _1146;\n                if (_1146 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1125);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _391, thread float4& gl_FragCoord, constant fa_shadows& _627, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1474 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2355 = _1474.direction;\n    float3 _2350 = _1474.color;\n    float _2352 = _1474.shadow;\n    int _2360 = _1474.type;\n    if ((_2360 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2355;\n        float _1488 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex, fa_world_pos);\n        _2352 = _1488;\n        _2350 *= _1488;\n    }\n    return LightSample{ _2355, _2350, _1474.attenuation, _2352, _1474._distance, _2360 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1378 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1381 = _1378.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1381 * _1381, exp2((-9.27999973297119140625) * ndv)) * _1381) + _1378.y)) + _1378.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _391, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_391.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _391.fa_env_horizon.w)).xyz;\n    }\n    float _1283 = rough * rough;\n    float _1313 = 0.60000002384185791015625 * _1283;\n    return mix(mix(_391.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_391.fa_env_horizon.xyz, _391.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1283)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1313, 0.0500000007450580596923828125 + _1313, d.y))), ((_391.fa_env_sky.xyz + _391.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1283 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _391, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1420 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _391, fa_env_tex, fa_env_smp) * ((f0 * _1420.x) + float3(_1420.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _627)\n{\n    if (_627.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1170 = int(_627.fa_shadow_cfg.x + 0.5);\n    float _1180 = dot(world - _627.fa_shadow_eye.xyz, _627.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1185 = _1170 > 0;\n    bool _1194;\n    if (_1185)\n    {\n        int param = _1170 - 1;\n        _1194 = _1180 <= fa_shadow_split_at(param, _627);\n    }\n    else\n    {\n        _1194 = _1185;\n    }\n    if (_1194)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1201 = _1170 > 1;\n        bool _1208;\n        if (_1201)\n        {\n            _1208 = _1180 > _627.fa_shadow_split.x;\n        }\n        else\n        {\n            _1208 = _1201;\n        }\n        if (_1208)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1214 = _1170 > 2;\n        bool _1221;\n        if (_1214)\n        {\n            _1221 = _1180 > _627.fa_shadow_split.y;\n        }\n        else\n        {\n            _1221 = _1214;\n        }\n        if (_1221)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1227 = _1170 > 3;\n        bool _1234;\n        if (_1227)\n        {\n            _1234 = _1180 > _627.fa_shadow_split.z;\n        }\n        else\n        {\n            _1234 = _1227;\n        }\n        if (_1234)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _391 [[buffer(1)]], constant fa_material& _1513 [[buffer(5)]], constant fa_shadows& _627 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2275 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2275 = -_2275;\n    }\n    float3 _1810 = fast::normalize(_391.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _391, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2275, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1810, short(gl_FrontFacing) };\n    Surface _1818 = fa_standard_surface(param_1, _391, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2298 = _1818.albedo;\n    float _2299 = _1818.alpha;\n    float3 _2300 = _1818.normal;\n    float _2301 = _1818.metallic;\n    float _2302 = _1818.roughness;\n    float _2303 = _1818.occlusion;\n    float3 _2304 = _1818.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2275, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1810, short(gl_FrontFacing) };\n    Surface param_3 = _1818;\n    surface(param_2, param_3, tint, _1513);\n    _2298 = param_3.albedo;\n    _2299 = param_3.alpha;\n    _2300 = param_3.normal;\n    _2301 = param_3.metallic;\n    _2302 = param_3.roughness;\n    _2303 = param_3.occlusion;\n    _2304 = param_3.emission;\n    float3 result;\n    if (_391.fa_emissive.w > 0.5)\n    {\n        result = _2298;\n    }\n    else\n    {\n        float3 _1840 = fast::normalize(_2300);\n        float _1847 = fast::clamp(_2301, 0.0, 1.0);\n        float _1851 = fast::clamp(_2302, 0.0500000007450580596923828125, 1.0);\n        float _1855 = _1851 * _1851;\n        float _1859 = _1855 * _1855;\n        float _1864 = fast::max(dot(_1840, _1810), 9.9999997473787516355514526367188e-05);\n        float3 _1870 = _2298 * (1.0 - _1847);\n        float3 _1878 = mix(float3(0.039999999105930328369140625), _2298, float3(_1847));\n        float3 param_4 = _1840;\n        float3 lit = (fa_ambient_light(param_4, _391, fa_env_smp, fa_irr_tex) * _1870) * _2303;\n        int _1891 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1891; ln++)\n        {\n            int param_5 = ln;\n            int _1904 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _391, fa_cl_ndir, fa_cl_slot);\n            int param_6 = _1904;\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2275;\n            LightSample _1913 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _391, gl_FragCoord, _627, fa_shadow_tex, in.fa_world_pos);\n            float3 _2333 = _1913.direction;\n            float _1921 = fast::max(dot(_1840, _2333), 0.0);\n            float3 _1932 = fast::normalize(_2333 + _1810);\n            float _1937 = fast::max(dot(_1840, _1932), 0.0);\n            float _1950 = ((_1937 * _1937) * (_1859 - 1.0)) + 1.0;\n            int param_9 = _1904;\n            lit += (((_1870 + (((_1878 + ((float3(1.0) - _1878) * powr(1.0 - fast::max(dot(_1810, _1932), 0.0), 5.0))) * (((_1859 / ((3.1415927410125732421875 * _1950) * _1950)) * (0.5 / fast::max(mix((2.0 * _1921) * _1864, _1921 + _1864, _1855), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1921))) * fa_light_rgb(param_9, fa_light_tex, fa_shadow_smp)) * (_1921 * (_1913.attenuation * _1913.shadow)));\n        }\n        float3 param_10 = _1840;\n        float3 param_11 = _1810;\n        float3 param_12 = _1878;\n        float param_13 = _1851;\n        float3 _2019 = lit;\n        float3 _2020 = _2019 + (fa_sky_reflection(param_10, param_11, param_12, param_13, _391, fa_env_tex, fa_env_smp) * _2303);\n        lit = _2020;\n        result = _2020;\n    }\n    float3 _2024 = result;\n    float3 _2025 = _2024 + _2304;\n    result = _2025;\n    float3 param_14 = _2025;\n    float3 param_15 = in.fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15, _627);\n    bool _2034 = _391.fa_fog.w > 0.0;\n    bool _2042;\n    if (!_2034)\n    {\n        _2042 = _391.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2042 = _2034;\n    }\n    if (_2042)\n    {\n        float3 _2051 = in.fa_world_pos - _391.fa_camera_pos.xyz;\n        float _2058 = dot(_2051, _391.fa_fog_c.xyz);\n        bool _2062 = _391.fa_fog_c.w > 0.5;\n        float _2063;\n        if (_2062)\n        {\n            _2063 = _2058;\n        }\n        else\n        {\n            _2063 = length(_2051);\n        }\n        float _2075 = _2063 - _391.fa_fog_b.x;\n        if (_2075 > 0.0)\n        {\n            float _2084 = _391.fa_fog.w * _2075;\n            float tau = _2084 * _2084;\n            if (_391.fa_fog_b.y > 0.0)\n            {\n                float _2100;\n                if (_2062)\n                {\n                    _2100 = in.fa_world_pos.y - (_391.fa_fog_c.y * _2058);\n                }\n                else\n                {\n                    _2100 = _391.fa_camera_pos.y;\n                }\n                float _2121 = mix(_2100, in.fa_world_pos.y, fast::clamp(_391.fa_fog_b.x / _2063, 0.0, 1.0));\n                float _2125 = in.fa_world_pos.y - _2121;\n                float _2130 = _2121 - _391.fa_fog_b.z;\n                float _2135 = in.fa_world_pos.y - _391.fa_fog_b.z;\n                bool _2138 = _2130 <= 0.0;\n                bool _2139 = !_2138;\n                bool _2145;\n                if (_2139)\n                {\n                    _2145 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2145 = _2138;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _391.fa_fog_b.y;\n                }\n                else\n                {\n                    _2146 = _391.fa_fog_b.y * exp(-fast::min(_391.fa_fog_b.w * _2130, 80.0));\n                }\n                bool _2173;\n                if (_2139)\n                {\n                    _2173 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2173 = _2138;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = _391.fa_fog_b.y * _2130;\n                }\n                else\n                {\n                    _2174 = (_391.fa_fog_b.y * (1.0 - exp(-fast::min(_391.fa_fog_b.w * _2130, 80.0)))) / _391.fa_fog_b.w;\n                }\n                bool _2199 = _2135 <= 0.0;\n                bool _2206;\n                if (!_2199)\n                {\n                    _2206 = _391.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2206 = _2199;\n                }\n                float _2207;\n                if (_2206)\n                {\n                    _2207 = _391.fa_fog_b.y * _2135;\n                }\n                else\n                {\n                    _2207 = (_391.fa_fog_b.y * (1.0 - exp(-fast::min(_391.fa_fog_b.w * _2135, 80.0)))) / _391.fa_fog_b.w;\n                }\n                float _2234;\n                if (abs(_2125) < 0.001000000047497451305389404296875)\n                {\n                    _2234 = _2146;\n                }\n                else\n                {\n                    _2234 = (_2207 - _2174) / _2125;\n                }\n                tau += (_2075 * fast::max(_2234, 0.0));\n            }\n            result = mix(result, _391.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2299);\n    return out;\n}\n\n",
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
            "inst_name": "_391",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_627",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1513",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _624 = base_t;\n    _624.x = _264.x;\n    _624.y = _264.y;\n    _624.z = _264.z;\n    base_t = _624;\n    float4 _280 = (_624 * _253.fa_base_color) * i.vertex_color;\n    float3 _605 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _632 = _317;\n        _632.x = _322.x;\n        _632.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _632;\n        _605 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _635 = mrt;\n    _635.x = _351.x;\n    _635.y = _351.y;\n    _635.z = _351.z;\n    mrt = _635;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _605, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _552 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _552 = -_552;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _552, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _552, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _624 = base_t;\n    _624.x = _264.x;\n    _624.y = _264.y;\n    _624.z = _264.z;\n    base_t = _624;\n    float4 _280 = (_624 * _253.fa_base_color) * i.vertex_color;\n    float3 _605 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _632 = _317;\n        _632.x = _322.x;\n        _632.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _632;\n        _605 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _635 = mrt;\n    _635.x = _351.x;\n    _635.y = _351.y;\n    _635.z = _351.z;\n    mrt = _635;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _605, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _552 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _552 = -_552;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _552, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _552, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
