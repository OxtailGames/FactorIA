{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1309 = fa_linear_to_srgb(param);\n        c = _1309;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1317 = fa_srgb_to_linear(param_1);\n            c = _1317;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _137;\n    if (bool(i.front_facing))\n    {\n        _137 = i.world_normal;\n    }\n    else\n    {\n        _137 = -i.world_normal;\n    }\n    float3 _161 = fast::normalize(i.world_tangent.xyz - (_137 * dot(_137, i.world_tangent.xyz)));\n    float3 _189 = fast::normalize(((_161 * m.x) + ((cross(_137, _161) * i.world_tangent.w) * m.y)) + (_137 * m.z));\n    float3 _192;\n    if (bool(i.front_facing))\n    {\n        _192 = _189;\n    }\n    else\n    {\n        _192 = -_189;\n    }\n    return _192;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _734, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _734.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1348 = fa_tex_fix(param_2, param_3);\n    float4 _2134 = base_t;\n    _2134.x = _1348.x;\n    _2134.y = _1348.y;\n    _2134.z = _1348.z;\n    base_t = _2134;\n    float4 _1362 = (_2134 * _734.fa_base_color) * i.vertex_color;\n    float3 _2102 = i.world_normal;\n    if (_734.fa_maps.z > 0.5)\n    {\n        float param_4 = _734.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1394 = fa_tex_fix(param_6, param_7);\n        float3 _1398 = (_1394 * 2.0) - float3(1.0);\n        float2 _1403 = _1398.xy * _734.fa_maps.x;\n        float3 _2142 = _1398;\n        _2142.x = _1403.x;\n        _2142.y = _1403.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2142;\n        _2102 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _734.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1432 = fa_tex_fix(param_12, param_13);\n    float4 _2145 = mrt;\n    _2145.x = _1432.x;\n    _2145.y = _1432.y;\n    _2145.z = _1432.z;\n    mrt = _2145;\n    float param_14 = _734.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1471 = fa_tex_fix(param_16, param_17);\n    float param_18 = _734.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1498 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1362.xyz, _1362.w, _2102, fast::clamp(_734.fa_pbr.x * _1432.z, 0.0, 1.0), fast::clamp(_734.fa_pbr.y * _1432.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_734.fa_maps.y * (_1471.x - 1.0)), _734.fa_emissive.xyz + (_734.fa_model_emissive.xyz * _1498) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _1244)\n{\n    s.emission += ((tint.xyz * tint.w) * _1244.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _734, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_734.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _734.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _209)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _220 = _209.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_220)\n    {\n        l = fast::normalize(_209.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _238 = _209.fa_light_pos[li].xyz - world_pos;\n        float _240 = length(_238);\n        dist = _240;\n        l = _238 / float3(fast::max(_240, 9.9999997473787516355514526367188e-05));\n        float _256 = _240 / fast::max(_209.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _262 = fast::clamp(1.0 - (_256 * _256), 0.0, 1.0);\n        atten = _262 * _262;\n        if (_209.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_209.fa_light_dir[li].w, mix(_209.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_209.fa_light_dir[li].xyz)));\n        }\n    }\n    int _313;\n    if (_220)\n    {\n        _313 = 0;\n    }\n    else\n    {\n        _313 = (_209.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _209.fa_light_color[li].xyz * atten, atten, 1.0, dist, _313 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _375)\n{\n    float _365;\n    if (i == 0)\n    {\n        _365 = _375.fa_shadow_split.x;\n    }\n    else\n    {\n        float _381;\n        if (i == 1)\n        {\n            _381 = _375.fa_shadow_split.y;\n        }\n        else\n        {\n            float _389;\n            if (i == 2)\n            {\n                _389 = _375.fa_shadow_split.z;\n            }\n            else\n            {\n                _389 = _375.fa_shadow_split.w;\n            }\n            _381 = _389;\n        }\n        _365 = _381;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _353 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_353), sin(_353)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _433 = fast::max(_375.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _438 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _444 = sqrt(1.0 - (_438 * _438));\n    float _452 = fast::min(_444 / fast::max(_438, 0.20000000298023223876953125), 4.0);\n    float _457;\n    if (_375.fa_shadow_bias.y > 0.0)\n    {\n        _457 = _375.fa_shadow_bias.y;\n    }\n    else\n    {\n        _457 = 1.5 * _375.fa_shadow_info[ci].x;\n    }\n    float4 _482 = _375.fa_shadow_mat[ci] * float4(world + (n * (_457 * _444)), 1.0);\n    float _489 = _482.x;\n    bool _492 = _489 < _375.fa_shadow_rect[ci].x;\n    bool _501;\n    if (!_492)\n    {\n        _501 = _489 > _375.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _501 = _492;\n    }\n    bool _510;\n    if (!_501)\n    {\n        _510 = _482.y < _375.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _510 = _501;\n    }\n    bool _519;\n    if (!_510)\n    {\n        _519 = _482.y > _375.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _519 = _510;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _482.z > 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return -1.0;\n    }\n    float _535;\n    if (_375.fa_shadow_bias.x > 0.0)\n    {\n        _535 = _375.fa_shadow_bias.x;\n    }\n    else\n    {\n        _535 = 1.5 * _375.fa_shadow_info[ci].x;\n    }\n    float _554 = _482.z - ((_535 * (1.0 + (0.5 * _452))) / _433);\n    float _563 = ((_375.fa_shadow_info[ci].x * fast::min(_452, 3.0)) * 0.5) / _433;\n    int _572 = int(_375.fa_shadow_cfg.z + 0.5);\n    if (_572 == 1)\n    {\n        float2 param = _482.xy;\n        float4 param_1 = _375.fa_shadow_rect[ci];\n        float _583 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_554 <= _583);\n    }\n    float _590 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _593 = _572 == 2;\n    if (_593)\n    {\n        float _607 = fast::clamp(((_375.fa_shadow_cfg.w * _433) * 0.25) / _375.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _590;\n            float2 _627 = fa_shadow_vogel(param_2, param_3, param_4) * _607;\n            float2 param_5 = _482.xy + (_627 * _375.fa_shadow_bias.zw);\n            float4 param_6 = _375.fa_shadow_rect[ci];\n            float _638 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_638 < (_554 - (length(_627) * _563)))\n            {\n                sum += _638;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_554 - (sum / cnt), 0.0) * _433) * _375.fa_shadow_cfg.w) / _375.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _682 = _593 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _682; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _682;\n        float param_9 = _590;\n        float2 _701 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _482.xy + (_701 * _375.fa_shadow_bias.zw);\n        float4 param_11 = _375.fa_shadow_rect[ci];\n        float _712 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_554 - (length(_701) * _563)) <= _712);\n    }\n    return lit / float(_682);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734)\n{\n    if (_734.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _745 = int(_375.fa_shadow_cfg.x + 0.5);\n    if (_745 < 1)\n    {\n        return 1.0;\n    }\n    float _761 = dot(world - _375.fa_shadow_eye.xyz, _375.fa_shadow_fwd.xyz);\n    int param = _745 - 1;\n    if (_761 > fa_shadow_split_at(param, _375))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _773 = _745 > 1;\n    bool _780;\n    if (_773)\n    {\n        _780 = _761 > _375.fa_shadow_split.x;\n    }\n    else\n    {\n        _780 = _773;\n    }\n    if (_780)\n    {\n        ci = 1;\n    }\n    bool _784 = _745 > 2;\n    bool _791;\n    if (_784)\n    {\n        _791 = _761 > _375.fa_shadow_split.y;\n    }\n    else\n    {\n        _791 = _784;\n    }\n    if (_791)\n    {\n        ci = 2;\n    }\n    bool _795 = _745 > 3;\n    bool _802;\n    if (_795)\n    {\n        _802 = _761 > _375.fa_shadow_split.z;\n    }\n    else\n    {\n        _802 = _795;\n    }\n    if (_802)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _745)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _828 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp);\n        s = _828;\n        if (_828 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_375.fa_shadow_cfg.y > 0.0)\n    {\n        float _853;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _853 = fa_shadow_split_at(param_5, _375);\n        }\n        else\n        {\n            _853 = _375.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _872 = _375.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _375) - _853, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _883 = fast::clamp((_761 - (fa_shadow_split_at(param_7, _375) - _872)) / _872, 0.0, 1.0);\n        if (_883 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _745)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _904 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp);\n                s2 = _904;\n                if (_904 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _883);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _209, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1200 = fa_light_sample(param, param_1, _209);\n    float3 _2087 = _1200.direction;\n    float3 _2082 = _1200.color;\n    float _2089 = _1200.attenuation;\n    float _2084 = _1200.shadow;\n    int _2092 = _1200.type;\n    if ((_2092 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2087;\n        float _1214 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734, fa_world_pos);\n        _2084 = _1214;\n        _2082 = _209.fa_light_color[li].xyz * (_2089 * _1214);\n    }\n    return LightSample{ _2087, _2082, _2089, _2084, _1200._distance, _2092 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1136 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1139 = _1136.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1139 * _1139, exp2((-9.27999973297119140625) * ndv)) * _1139) + _1136.y)) + _1136.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _734, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_734.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _734.fa_env_horizon.w)).xyz;\n    }\n    float _1041 = rough * rough;\n    float _1071 = 0.60000002384185791015625 * _1041;\n    return mix(mix(_734.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_734.fa_env_horizon.xyz, _734.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1041)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1071, 0.0500000007450580596923828125 + _1071, d.y))), ((_734.fa_env_sky.xyz + _734.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1041 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _734, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1178 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _734, fa_env_tex, fa_env_smp) * ((f0 * _1178.x) + float3(_1178.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _375)\n{\n    if (_375.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _928 = int(_375.fa_shadow_cfg.x + 0.5);\n    float _938 = dot(world - _375.fa_shadow_eye.xyz, _375.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _943 = _928 > 0;\n    bool _952;\n    if (_943)\n    {\n        int param = _928 - 1;\n        _952 = _938 <= fa_shadow_split_at(param, _375);\n    }\n    else\n    {\n        _952 = _943;\n    }\n    if (_952)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _959 = _928 > 1;\n        bool _966;\n        if (_959)\n        {\n            _966 = _938 > _375.fa_shadow_split.x;\n        }\n        else\n        {\n            _966 = _959;\n        }\n        if (_966)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _972 = _928 > 2;\n        bool _979;\n        if (_972)\n        {\n            _979 = _938 > _375.fa_shadow_split.y;\n        }\n        else\n        {\n            _979 = _972;\n        }\n        if (_979)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _985 = _928 > 3;\n        bool _992;\n        if (_985)\n        {\n            _992 = _938 > _375.fa_shadow_split.z;\n        }\n        else\n        {\n            _992 = _985;\n        }\n        if (_992)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _734 [[buffer(1)]], constant fa_lights& _209 [[buffer(2)]], constant fa_material& _1244 [[buffer(5)]], constant fa_shadows& _375 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2007 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2007 = -_2007;\n    }\n    float3 _1541 = fast::normalize(_734.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2007, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1541, short(gl_FrontFacing) };\n    Surface _1546 = fa_standard_surface(param, _734, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2030 = _1546.albedo;\n    float _2031 = _1546.alpha;\n    float3 _2032 = _1546.normal;\n    float _2033 = _1546.metallic;\n    float _2034 = _1546.roughness;\n    float _2035 = _1546.occlusion;\n    float3 _2036 = _1546.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2007, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1541, short(gl_FrontFacing) };\n    Surface param_2 = _1546;\n    surface(param_1, param_2, tint, _1244);\n    _2030 = param_2.albedo;\n    _2031 = param_2.alpha;\n    _2032 = param_2.normal;\n    _2033 = param_2.metallic;\n    _2034 = param_2.roughness;\n    _2035 = param_2.occlusion;\n    _2036 = param_2.emission;\n    float3 result;\n    if (_734.fa_emissive.w > 0.5)\n    {\n        result = _2030;\n    }\n    else\n    {\n        float3 _1568 = fast::normalize(_2032);\n        float _1575 = fast::clamp(_2033, 0.0, 1.0);\n        float _1579 = fast::clamp(_2034, 0.0500000007450580596923828125, 1.0);\n        float _1583 = _1579 * _1579;\n        float _1587 = _1583 * _1583;\n        float _1592 = fast::max(dot(_1568, _1541), 9.9999997473787516355514526367188e-05);\n        float3 _1598 = _2030 * (1.0 - _1575);\n        float3 _1606 = mix(float3(0.039999999105930328369140625), _2030, float3(_1575));\n        float3 param_3 = _1568;\n        float3 lit = (fa_ambient_light(param_3, _734, fa_env_smp, fa_irr_tex) * _1598) * _2035;\n        int _1620 = int(_734.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1620)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _2007;\n            LightSample _1644 = fa_light_shadowed(param_4, param_5, param_6, _209, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734, in.fa_world_pos);\n            float3 _2065 = _1644.direction;\n            float _1652 = fast::max(dot(_1568, _2065), 0.0);\n            float3 _1663 = fast::normalize(_2065 + _1541);\n            float _1668 = fast::max(dot(_1568, _1663), 0.0);\n            float _1681 = ((_1668 * _1668) * (_1587 - 1.0)) + 1.0;\n            lit += (((_1598 + (((_1606 + ((float3(1.0) - _1606) * powr(1.0 - fast::max(dot(_1541, _1663), 0.0), 5.0))) * (((_1587 / ((3.1415927410125732421875 * _1681) * _1681)) * (0.5 / fast::max(mix((2.0 * _1652) * _1592, _1652 + _1592, _1583), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1652))) * _209.fa_light_color[li].xyz) * (_1652 * (_1644.attenuation * _1644.shadow)));\n        }\n        float3 param_7 = _1568;\n        float3 param_8 = _1541;\n        float3 param_9 = _1606;\n        float param_10 = _1579;\n        float3 _1751 = lit;\n        float3 _1752 = _1751 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _734, fa_env_tex, fa_env_smp) * _2035);\n        lit = _1752;\n        result = _1752;\n    }\n    float3 _1756 = result;\n    float3 _1757 = _1756 + _2036;\n    result = _1757;\n    float3 param_11 = _1757;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _375);\n    bool _1766 = _734.fa_fog.w > 0.0;\n    bool _1774;\n    if (!_1766)\n    {\n        _1774 = _734.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1774 = _1766;\n    }\n    if (_1774)\n    {\n        float3 _1783 = in.fa_world_pos - _734.fa_camera_pos.xyz;\n        float _1790 = dot(_1783, _734.fa_fog_c.xyz);\n        bool _1794 = _734.fa_fog_c.w > 0.5;\n        float _1795;\n        if (_1794)\n        {\n            _1795 = _1790;\n        }\n        else\n        {\n            _1795 = length(_1783);\n        }\n        float _1807 = _1795 - _734.fa_fog_b.x;\n        if (_1807 > 0.0)\n        {\n            float _1816 = _734.fa_fog.w * _1807;\n            float tau = _1816 * _1816;\n            if (_734.fa_fog_b.y > 0.0)\n            {\n                float _1832;\n                if (_1794)\n                {\n                    _1832 = in.fa_world_pos.y - (_734.fa_fog_c.y * _1790);\n                }\n                else\n                {\n                    _1832 = _734.fa_camera_pos.y;\n                }\n                float _1853 = mix(_1832, in.fa_world_pos.y, fast::clamp(_734.fa_fog_b.x / _1795, 0.0, 1.0));\n                float _1857 = in.fa_world_pos.y - _1853;\n                float _1862 = _1853 - _734.fa_fog_b.z;\n                float _1867 = in.fa_world_pos.y - _734.fa_fog_b.z;\n                bool _1870 = _1862 <= 0.0;\n                bool _1871 = !_1870;\n                bool _1877;\n                if (_1871)\n                {\n                    _1877 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1877 = _1870;\n                }\n                float _1878;\n                if (_1877)\n                {\n                    _1878 = _734.fa_fog_b.y;\n                }\n                else\n                {\n                    _1878 = _734.fa_fog_b.y * exp(-fast::min(_734.fa_fog_b.w * _1862, 80.0));\n                }\n                bool _1905;\n                if (_1871)\n                {\n                    _1905 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1905 = _1870;\n                }\n                float _1906;\n                if (_1905)\n                {\n                    _1906 = _734.fa_fog_b.y * _1862;\n                }\n                else\n                {\n                    _1906 = (_734.fa_fog_b.y * (1.0 - exp(-fast::min(_734.fa_fog_b.w * _1862, 80.0)))) / _734.fa_fog_b.w;\n                }\n                bool _1931 = _1867 <= 0.0;\n                bool _1938;\n                if (!_1931)\n                {\n                    _1938 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1938 = _1931;\n                }\n                float _1939;\n                if (_1938)\n                {\n                    _1939 = _734.fa_fog_b.y * _1867;\n                }\n                else\n                {\n                    _1939 = (_734.fa_fog_b.y * (1.0 - exp(-fast::min(_734.fa_fog_b.w * _1867, 80.0)))) / _734.fa_fog_b.w;\n                }\n                float _1966;\n                if (abs(_1857) < 0.001000000047497451305389404296875)\n                {\n                    _1966 = _1878;\n                }\n                else\n                {\n                    _1966 = (_1939 - _1906) / _1857;\n                }\n                tau += (_1807 * fast::max(_1966, 0.0));\n            }\n            result = mix(result, _734.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2031);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_209",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_375",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_734",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1244",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1309 = fa_linear_to_srgb(param);\n        c = _1309;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1317 = fa_srgb_to_linear(param_1);\n            c = _1317;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _137;\n    if (bool(i.front_facing))\n    {\n        _137 = i.world_normal;\n    }\n    else\n    {\n        _137 = -i.world_normal;\n    }\n    float3 _161 = fast::normalize(i.world_tangent.xyz - (_137 * dot(_137, i.world_tangent.xyz)));\n    float3 _189 = fast::normalize(((_161 * m.x) + ((cross(_137, _161) * i.world_tangent.w) * m.y)) + (_137 * m.z));\n    float3 _192;\n    if (bool(i.front_facing))\n    {\n        _192 = _189;\n    }\n    else\n    {\n        _192 = -_189;\n    }\n    return _192;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _734, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _734.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1348 = fa_tex_fix(param_2, param_3);\n    float4 _2134 = base_t;\n    _2134.x = _1348.x;\n    _2134.y = _1348.y;\n    _2134.z = _1348.z;\n    base_t = _2134;\n    float4 _1362 = (_2134 * _734.fa_base_color) * i.vertex_color;\n    float3 _2102 = i.world_normal;\n    if (_734.fa_maps.z > 0.5)\n    {\n        float param_4 = _734.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1394 = fa_tex_fix(param_6, param_7);\n        float3 _1398 = (_1394 * 2.0) - float3(1.0);\n        float2 _1403 = _1398.xy * _734.fa_maps.x;\n        float3 _2142 = _1398;\n        _2142.x = _1403.x;\n        _2142.y = _1403.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2142;\n        _2102 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _734.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1432 = fa_tex_fix(param_12, param_13);\n    float4 _2145 = mrt;\n    _2145.x = _1432.x;\n    _2145.y = _1432.y;\n    _2145.z = _1432.z;\n    mrt = _2145;\n    float param_14 = _734.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1471 = fa_tex_fix(param_16, param_17);\n    float param_18 = _734.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1498 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1362.xyz, _1362.w, _2102, fast::clamp(_734.fa_pbr.x * _1432.z, 0.0, 1.0), fast::clamp(_734.fa_pbr.y * _1432.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_734.fa_maps.y * (_1471.x - 1.0)), _734.fa_emissive.xyz + (_734.fa_model_emissive.xyz * _1498) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _1244)\n{\n    s.emission += ((tint.xyz * tint.w) * _1244.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _734, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_734.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _734.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _209)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _220 = _209.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_220)\n    {\n        l = fast::normalize(_209.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _238 = _209.fa_light_pos[li].xyz - world_pos;\n        float _240 = length(_238);\n        dist = _240;\n        l = _238 / float3(fast::max(_240, 9.9999997473787516355514526367188e-05));\n        float _256 = _240 / fast::max(_209.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _262 = fast::clamp(1.0 - (_256 * _256), 0.0, 1.0);\n        atten = _262 * _262;\n        if (_209.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_209.fa_light_dir[li].w, mix(_209.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_209.fa_light_dir[li].xyz)));\n        }\n    }\n    int _313;\n    if (_220)\n    {\n        _313 = 0;\n    }\n    else\n    {\n        _313 = (_209.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _209.fa_light_color[li].xyz * atten, atten, 1.0, dist, _313 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _375)\n{\n    float _365;\n    if (i == 0)\n    {\n        _365 = _375.fa_shadow_split.x;\n    }\n    else\n    {\n        float _381;\n        if (i == 1)\n        {\n            _381 = _375.fa_shadow_split.y;\n        }\n        else\n        {\n            float _389;\n            if (i == 2)\n            {\n                _389 = _375.fa_shadow_split.z;\n            }\n            else\n            {\n                _389 = _375.fa_shadow_split.w;\n            }\n            _381 = _389;\n        }\n        _365 = _381;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _353 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_353), sin(_353)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _433 = fast::max(_375.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _438 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _444 = sqrt(1.0 - (_438 * _438));\n    float _452 = fast::min(_444 / fast::max(_438, 0.20000000298023223876953125), 4.0);\n    float _457;\n    if (_375.fa_shadow_bias.y > 0.0)\n    {\n        _457 = _375.fa_shadow_bias.y;\n    }\n    else\n    {\n        _457 = 1.5 * _375.fa_shadow_info[ci].x;\n    }\n    float4 _482 = _375.fa_shadow_mat[ci] * float4(world + (n * (_457 * _444)), 1.0);\n    float _489 = _482.x;\n    bool _492 = _489 < _375.fa_shadow_rect[ci].x;\n    bool _501;\n    if (!_492)\n    {\n        _501 = _489 > _375.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _501 = _492;\n    }\n    bool _510;\n    if (!_501)\n    {\n        _510 = _482.y < _375.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _510 = _501;\n    }\n    bool _519;\n    if (!_510)\n    {\n        _519 = _482.y > _375.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _519 = _510;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _482.z > 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return -1.0;\n    }\n    float _535;\n    if (_375.fa_shadow_bias.x > 0.0)\n    {\n        _535 = _375.fa_shadow_bias.x;\n    }\n    else\n    {\n        _535 = 1.5 * _375.fa_shadow_info[ci].x;\n    }\n    float _554 = _482.z - ((_535 * (1.0 + (0.5 * _452))) / _433);\n    float _563 = ((_375.fa_shadow_info[ci].x * fast::min(_452, 3.0)) * 0.5) / _433;\n    int _572 = int(_375.fa_shadow_cfg.z + 0.5);\n    if (_572 == 1)\n    {\n        float2 param = _482.xy;\n        float4 param_1 = _375.fa_shadow_rect[ci];\n        float _583 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_554 <= _583);\n    }\n    float _590 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _593 = _572 == 2;\n    if (_593)\n    {\n        float _607 = fast::clamp(((_375.fa_shadow_cfg.w * _433) * 0.25) / _375.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _590;\n            float2 _627 = fa_shadow_vogel(param_2, param_3, param_4) * _607;\n            float2 param_5 = _482.xy + (_627 * _375.fa_shadow_bias.zw);\n            float4 param_6 = _375.fa_shadow_rect[ci];\n            float _638 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_638 < (_554 - (length(_627) * _563)))\n            {\n                sum += _638;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_554 - (sum / cnt), 0.0) * _433) * _375.fa_shadow_cfg.w) / _375.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _682 = _593 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _682; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _682;\n        float param_9 = _590;\n        float2 _701 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _482.xy + (_701 * _375.fa_shadow_bias.zw);\n        float4 param_11 = _375.fa_shadow_rect[ci];\n        float _712 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_554 - (length(_701) * _563)) <= _712);\n    }\n    return lit / float(_682);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734)\n{\n    if (_734.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _745 = int(_375.fa_shadow_cfg.x + 0.5);\n    if (_745 < 1)\n    {\n        return 1.0;\n    }\n    float _761 = dot(world - _375.fa_shadow_eye.xyz, _375.fa_shadow_fwd.xyz);\n    int param = _745 - 1;\n    if (_761 > fa_shadow_split_at(param, _375))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _773 = _745 > 1;\n    bool _780;\n    if (_773)\n    {\n        _780 = _761 > _375.fa_shadow_split.x;\n    }\n    else\n    {\n        _780 = _773;\n    }\n    if (_780)\n    {\n        ci = 1;\n    }\n    bool _784 = _745 > 2;\n    bool _791;\n    if (_784)\n    {\n        _791 = _761 > _375.fa_shadow_split.y;\n    }\n    else\n    {\n        _791 = _784;\n    }\n    if (_791)\n    {\n        ci = 2;\n    }\n    bool _795 = _745 > 3;\n    bool _802;\n    if (_795)\n    {\n        _802 = _761 > _375.fa_shadow_split.z;\n    }\n    else\n    {\n        _802 = _795;\n    }\n    if (_802)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _745)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _828 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp);\n        s = _828;\n        if (_828 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_375.fa_shadow_cfg.y > 0.0)\n    {\n        float _853;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _853 = fa_shadow_split_at(param_5, _375);\n        }\n        else\n        {\n            _853 = _375.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _872 = _375.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _375) - _853, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _883 = fast::clamp((_761 - (fa_shadow_split_at(param_7, _375) - _872)) / _872, 0.0, 1.0);\n        if (_883 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _745)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _904 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp);\n                s2 = _904;\n                if (_904 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _883);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _209, thread float4& gl_FragCoord, constant fa_shadows& _375, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _734, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1200 = fa_light_sample(param, param_1, _209);\n    float3 _2087 = _1200.direction;\n    float3 _2082 = _1200.color;\n    float _2089 = _1200.attenuation;\n    float _2084 = _1200.shadow;\n    int _2092 = _1200.type;\n    if ((_2092 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2087;\n        float _1214 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734, fa_world_pos);\n        _2084 = _1214;\n        _2082 = _209.fa_light_color[li].xyz * (_2089 * _1214);\n    }\n    return LightSample{ _2087, _2082, _2089, _2084, _1200._distance, _2092 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1136 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1139 = _1136.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1139 * _1139, exp2((-9.27999973297119140625) * ndv)) * _1139) + _1136.y)) + _1136.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _734, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_734.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _734.fa_env_horizon.w)).xyz;\n    }\n    float _1041 = rough * rough;\n    float _1071 = 0.60000002384185791015625 * _1041;\n    return mix(mix(_734.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_734.fa_env_horizon.xyz, _734.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1041)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1071, 0.0500000007450580596923828125 + _1071, d.y))), ((_734.fa_env_sky.xyz + _734.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1041 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _734, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1178 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _734, fa_env_tex, fa_env_smp) * ((f0 * _1178.x) + float3(_1178.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _375)\n{\n    if (_375.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _928 = int(_375.fa_shadow_cfg.x + 0.5);\n    float _938 = dot(world - _375.fa_shadow_eye.xyz, _375.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _943 = _928 > 0;\n    bool _952;\n    if (_943)\n    {\n        int param = _928 - 1;\n        _952 = _938 <= fa_shadow_split_at(param, _375);\n    }\n    else\n    {\n        _952 = _943;\n    }\n    if (_952)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _959 = _928 > 1;\n        bool _966;\n        if (_959)\n        {\n            _966 = _938 > _375.fa_shadow_split.x;\n        }\n        else\n        {\n            _966 = _959;\n        }\n        if (_966)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _972 = _928 > 2;\n        bool _979;\n        if (_972)\n        {\n            _979 = _938 > _375.fa_shadow_split.y;\n        }\n        else\n        {\n            _979 = _972;\n        }\n        if (_979)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _985 = _928 > 3;\n        bool _992;\n        if (_985)\n        {\n            _992 = _938 > _375.fa_shadow_split.z;\n        }\n        else\n        {\n            _992 = _985;\n        }\n        if (_992)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _734 [[buffer(1)]], constant fa_lights& _209 [[buffer(2)]], constant fa_material& _1244 [[buffer(5)]], constant fa_shadows& _375 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _2007 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2007 = -_2007;\n    }\n    float3 _1541 = fast::normalize(_734.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2007, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1541, short(gl_FrontFacing) };\n    Surface _1546 = fa_standard_surface(param, _734, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2030 = _1546.albedo;\n    float _2031 = _1546.alpha;\n    float3 _2032 = _1546.normal;\n    float _2033 = _1546.metallic;\n    float _2034 = _1546.roughness;\n    float _2035 = _1546.occlusion;\n    float3 _2036 = _1546.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2007, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1541, short(gl_FrontFacing) };\n    Surface param_2 = _1546;\n    surface(param_1, param_2, tint, _1244);\n    _2030 = param_2.albedo;\n    _2031 = param_2.alpha;\n    _2032 = param_2.normal;\n    _2033 = param_2.metallic;\n    _2034 = param_2.roughness;\n    _2035 = param_2.occlusion;\n    _2036 = param_2.emission;\n    float3 result;\n    if (_734.fa_emissive.w > 0.5)\n    {\n        result = _2030;\n    }\n    else\n    {\n        float3 _1568 = fast::normalize(_2032);\n        float _1575 = fast::clamp(_2033, 0.0, 1.0);\n        float _1579 = fast::clamp(_2034, 0.0500000007450580596923828125, 1.0);\n        float _1583 = _1579 * _1579;\n        float _1587 = _1583 * _1583;\n        float _1592 = fast::max(dot(_1568, _1541), 9.9999997473787516355514526367188e-05);\n        float3 _1598 = _2030 * (1.0 - _1575);\n        float3 _1606 = mix(float3(0.039999999105930328369140625), _2030, float3(_1575));\n        float3 param_3 = _1568;\n        float3 lit = (fa_ambient_light(param_3, _734, fa_env_smp, fa_irr_tex) * _1598) * _2035;\n        int _1620 = int(_734.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1620)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _2007;\n            LightSample _1644 = fa_light_shadowed(param_4, param_5, param_6, _209, gl_FragCoord, _375, fa_shadow_tex, fa_shadow_smp, _734, in.fa_world_pos);\n            float3 _2065 = _1644.direction;\n            float _1652 = fast::max(dot(_1568, _2065), 0.0);\n            float3 _1663 = fast::normalize(_2065 + _1541);\n            float _1668 = fast::max(dot(_1568, _1663), 0.0);\n            float _1681 = ((_1668 * _1668) * (_1587 - 1.0)) + 1.0;\n            lit += (((_1598 + (((_1606 + ((float3(1.0) - _1606) * powr(1.0 - fast::max(dot(_1541, _1663), 0.0), 5.0))) * (((_1587 / ((3.1415927410125732421875 * _1681) * _1681)) * (0.5 / fast::max(mix((2.0 * _1652) * _1592, _1652 + _1592, _1583), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1652))) * _209.fa_light_color[li].xyz) * (_1652 * (_1644.attenuation * _1644.shadow)));\n        }\n        float3 param_7 = _1568;\n        float3 param_8 = _1541;\n        float3 param_9 = _1606;\n        float param_10 = _1579;\n        float3 _1751 = lit;\n        float3 _1752 = _1751 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _734, fa_env_tex, fa_env_smp) * _2035);\n        lit = _1752;\n        result = _1752;\n    }\n    float3 _1756 = result;\n    float3 _1757 = _1756 + _2036;\n    result = _1757;\n    float3 param_11 = _1757;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _375);\n    bool _1766 = _734.fa_fog.w > 0.0;\n    bool _1774;\n    if (!_1766)\n    {\n        _1774 = _734.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1774 = _1766;\n    }\n    if (_1774)\n    {\n        float3 _1783 = in.fa_world_pos - _734.fa_camera_pos.xyz;\n        float _1790 = dot(_1783, _734.fa_fog_c.xyz);\n        bool _1794 = _734.fa_fog_c.w > 0.5;\n        float _1795;\n        if (_1794)\n        {\n            _1795 = _1790;\n        }\n        else\n        {\n            _1795 = length(_1783);\n        }\n        float _1807 = _1795 - _734.fa_fog_b.x;\n        if (_1807 > 0.0)\n        {\n            float _1816 = _734.fa_fog.w * _1807;\n            float tau = _1816 * _1816;\n            if (_734.fa_fog_b.y > 0.0)\n            {\n                float _1832;\n                if (_1794)\n                {\n                    _1832 = in.fa_world_pos.y - (_734.fa_fog_c.y * _1790);\n                }\n                else\n                {\n                    _1832 = _734.fa_camera_pos.y;\n                }\n                float _1853 = mix(_1832, in.fa_world_pos.y, fast::clamp(_734.fa_fog_b.x / _1795, 0.0, 1.0));\n                float _1857 = in.fa_world_pos.y - _1853;\n                float _1862 = _1853 - _734.fa_fog_b.z;\n                float _1867 = in.fa_world_pos.y - _734.fa_fog_b.z;\n                bool _1870 = _1862 <= 0.0;\n                bool _1871 = !_1870;\n                bool _1877;\n                if (_1871)\n                {\n                    _1877 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1877 = _1870;\n                }\n                float _1878;\n                if (_1877)\n                {\n                    _1878 = _734.fa_fog_b.y;\n                }\n                else\n                {\n                    _1878 = _734.fa_fog_b.y * exp(-fast::min(_734.fa_fog_b.w * _1862, 80.0));\n                }\n                bool _1905;\n                if (_1871)\n                {\n                    _1905 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1905 = _1870;\n                }\n                float _1906;\n                if (_1905)\n                {\n                    _1906 = _734.fa_fog_b.y * _1862;\n                }\n                else\n                {\n                    _1906 = (_734.fa_fog_b.y * (1.0 - exp(-fast::min(_734.fa_fog_b.w * _1862, 80.0)))) / _734.fa_fog_b.w;\n                }\n                bool _1931 = _1867 <= 0.0;\n                bool _1938;\n                if (!_1931)\n                {\n                    _1938 = _734.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1938 = _1931;\n                }\n                float _1939;\n                if (_1938)\n                {\n                    _1939 = _734.fa_fog_b.y * _1867;\n                }\n                else\n                {\n                    _1939 = (_734.fa_fog_b.y * (1.0 - exp(-fast::min(_734.fa_fog_b.w * _1867, 80.0)))) / _734.fa_fog_b.w;\n                }\n                float _1966;\n                if (abs(_1857) < 0.001000000047497451305389404296875)\n                {\n                    _1966 = _1878;\n                }\n                else\n                {\n                    _1966 = (_1939 - _1906) / _1857;\n                }\n                tau += (_1807 * fast::max(_1966, 0.0));\n            }\n            result = mix(result, _734.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2031);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_209",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_375",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_734",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1244",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _623 = base_t;\n    _623.x = _264.x;\n    _623.y = _264.y;\n    _623.z = _264.z;\n    base_t = _623;\n    float4 _280 = (_623 * _253.fa_base_color) * i.vertex_color;\n    float3 _604 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _631 = _317;\n        _631.x = _322.x;\n        _631.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _631;\n        _604 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _634 = mrt;\n    _634.x = _351.x;\n    _634.y = _351.y;\n    _634.z = _351.z;\n    mrt = _634;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _604, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _551 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _551 = -_551;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _551, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _551, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _623 = base_t;\n    _623.x = _264.x;\n    _623.y = _264.y;\n    _623.z = _264.z;\n    base_t = _623;\n    float4 _280 = (_623 * _253.fa_base_color) * i.vertex_color;\n    float3 _604 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _631 = _317;\n        _631.x = _322.x;\n        _631.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _631;\n        _604 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _634 = mrt;\n    _634.x = _351.x;\n    _634.y = _351.y;\n    _634.z = _351.z;\n    mrt = _634;\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface{ _280.xyz, _280.w, _604, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_392.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _419) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _551 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _551 = -_551;\n    }\n    float3 _464 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _551, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _551, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _464, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _479 = fast::normalize(param_2.normal);\n    float3 _494 = fast::normalize(float3(dot(in.fa_pre_r0, _479), dot(in.fa_pre_r1, _479), dot(in.fa_pre_r2, _479)));\n    float _506 = _494.z;\n    float2 e = _494.xy / float2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
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
