{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "metal_macos",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _274 = _160.world_pos;\n    fa_world_pos = _274;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_274, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1284 = fa_linear_to_srgb(param);\n        c = _1284;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1292 = fa_srgb_to_linear(param_1);\n            c = _1292;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _131;\n    if (bool(i.front_facing))\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = fast::normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = fast::normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (bool(i.front_facing))\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _728, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _728.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1323 = fa_tex_fix(param_2, param_3);\n    float4 _2119 = base_t;\n    _2119.x = _1323.x;\n    _2119.y = _1323.y;\n    _2119.z = _1323.z;\n    base_t = _2119;\n    float4 _1337 = (_2119 * _728.fa_base_color) * i.vertex_color;\n    float3 _2087 = i.world_normal;\n    if (_728.fa_maps.z > 0.5)\n    {\n        float param_4 = _728.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1369 = fa_tex_fix(param_6, param_7);\n        float3 _1372 = (_1369 * 2.0) - float3(1.0);\n        float2 _1377 = _1372.xy * _728.fa_maps.x;\n        float3 _2127 = _1372;\n        _2127.x = _1377.x;\n        _2127.y = _1377.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2127;\n        _2087 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _728.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1406 = fa_tex_fix(param_12, param_13);\n    float4 _2130 = mrt;\n    _2130.x = _1406.x;\n    _2130.y = _1406.y;\n    _2130.z = _1406.z;\n    mrt = _2130;\n    float param_14 = _728.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1445 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1472 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1337.xyz, _1337.w, _2087, fast::clamp(_728.fa_pbr.x * _1406.z, 0.0, 1.0), fast::clamp(_728.fa_pbr.y * _1406.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_728.fa_maps.y * (_1445.x - 1.0)), _728.fa_emissive.xyz + (_728.fa_model_emissive.xyz * _1472) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _728, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _728.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _203)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = _203.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_214)\n    {\n        l = fast::normalize(_203.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203.fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / float3(fast::max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / fast::max(_203.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _256 = fast::clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (_203.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_203.fa_light_dir[li].w, mix(_203.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_203.fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _203.fa_light_color[li].xyz * atten, atten, 1.0, dist, _307 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _369)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369.fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369.fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369.fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369.fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _427 = fast::max(_369.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = fast::min(_438 / fast::max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (_369.fa_shadow_bias.y > 0.0)\n    {\n        _451 = _369.fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float4 _476 = _369.fa_shadow_mat[ci] * float4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < _369.fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (_369.fa_shadow_bias.x > 0.0)\n    {\n        _529 = _369.fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((_369.fa_shadow_info[ci].x * fast::min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(_369.fa_shadow_cfg.z + 0.5);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369.fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = fast::clamp(((_369.fa_shadow_cfg.w * _427) * 0.25) / _369.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369.fa_shadow_bias.zw);\n            float4 param_6 = _369.fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_548 - (sum / cnt), 0.0) * _427) * _369.fa_shadow_cfg.w) / _369.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369.fa_shadow_bias.zw);\n        float4 param_11 = _369.fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728)\n{\n    if (_728.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(_369.fa_shadow_cfg.x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param, _369))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369.fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369.fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369.fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_369.fa_shadow_cfg.y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5, _369);\n        }\n        else\n        {\n            _847 = _369.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _369) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = fast::clamp((_755 - (fa_shadow_split_at(param_7, _369) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _203, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1, _203);\n    float3 _2072 = _1194.direction;\n    float3 _2067 = _1194.color;\n    float _2074 = _1194.attenuation;\n    float _2069 = _1194.shadow;\n    int _2077 = _1194.type;\n    if ((_2077 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2072;\n        float _1208 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, fa_world_pos);\n        _2069 = _1208;\n        _2067 = _203.fa_light_color[li].xyz * (_2074 * _1208);\n    }\n    return LightSample{ _2072, _2067, _2074, _2069, _1194._distance, _2077 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1130 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _728.fa_env_horizon.w)).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(_728.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_728.fa_env_horizon.xyz, _728.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((_728.fa_env_sky.xyz + _728.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1035 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _728, fa_env_tex, fa_env_smp) * ((f0 * _1172.x) + float3(_1172.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _369)\n{\n    if (_369.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(_369.fa_shadow_cfg.x + 0.5);\n    float _932 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param, _369);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369.fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369.fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369.fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _728 [[buffer(1)]], constant fa_lights& _203 [[buffer(2)]], constant fa_material& _1531 [[buffer(5)]], constant fa_shadows& _369 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1992 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1515 = fast::normalize(_728.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1515, short(gl_FrontFacing) };\n    Surface _1520 = fa_standard_surface(param, _728, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2015 = _1520.albedo;\n    float _2016 = _1520.alpha;\n    float3 _2017 = _1520.normal;\n    float _2018 = _1520.metallic;\n    float _2019 = _1520.roughness;\n    float _2020 = _1520.occlusion;\n    float3 _2021 = _1520.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1515, short(gl_FrontFacing) };\n    Surface param_2 = _1520;\n    surface(param_1, param_2, mask, mask_smp);\n    _2015 = param_2.albedo;\n    _2016 = param_2.alpha;\n    _2017 = param_2.normal;\n    _2018 = param_2.metallic;\n    _2019 = param_2.roughness;\n    _2020 = param_2.occlusion;\n    _2021 = param_2.emission;\n    if (param_2.alpha < _1531.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_728.fa_emissive.w > 0.5)\n    {\n        result = _2015;\n    }\n    else\n    {\n        float3 _1553 = fast::normalize(_2017);\n        float _1560 = fast::clamp(_2018, 0.0, 1.0);\n        float _1564 = fast::clamp(_2019, 0.0500000007450580596923828125, 1.0);\n        float _1568 = _1564 * _1564;\n        float _1572 = _1568 * _1568;\n        float _1577 = fast::max(dot(_1553, _1515), 9.9999997473787516355514526367188e-05);\n        float3 _1583 = _2015 * (1.0 - _1560);\n        float3 _1591 = mix(float3(0.039999999105930328369140625), _2015, float3(_1560));\n        float3 param_3 = _1553;\n        float3 lit = (fa_ambient_light(param_3, _728, fa_env_smp, fa_irr_tex) * _1583) * _2020;\n        int _1605 = int(_728.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1605)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1992;\n            LightSample _1629 = fa_light_shadowed(param_4, param_5, param_6, _203, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, in.fa_world_pos);\n            float3 _2050 = _1629.direction;\n            float _1637 = fast::max(dot(_1553, _2050), 0.0);\n            float3 _1648 = fast::normalize(_2050 + _1515);\n            float _1653 = fast::max(dot(_1553, _1648), 0.0);\n            float _1666 = ((_1653 * _1653) * (_1572 - 1.0)) + 1.0;\n            lit += (((_1583 + (((_1591 + ((float3(1.0) - _1591) * powr(1.0 - fast::max(dot(_1515, _1648), 0.0), 5.0))) * (((_1572 / ((3.1415927410125732421875 * _1666) * _1666)) * (0.5 / fast::max(mix((2.0 * _1637) * _1577, _1637 + _1577, _1568), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1637))) * _203.fa_light_color[li].xyz) * (_1637 * (_1629.attenuation * _1629.shadow)));\n        }\n        float3 param_7 = _1553;\n        float3 param_8 = _1515;\n        float3 param_9 = _1591;\n        float param_10 = _1564;\n        float3 _1736 = lit;\n        float3 _1737 = _1736 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _728, fa_env_tex, fa_env_smp) * _2020);\n        lit = _1737;\n        result = _1737;\n    }\n    float3 _1741 = result;\n    float3 _1742 = _1741 + _2021;\n    result = _1742;\n    float3 param_11 = _1742;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _369);\n    bool _1751 = _728.fa_fog.w > 0.0;\n    bool _1759;\n    if (!_1751)\n    {\n        _1759 = _728.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1759 = _1751;\n    }\n    if (_1759)\n    {\n        float3 _1768 = in.fa_world_pos - _728.fa_camera_pos.xyz;\n        float _1775 = dot(_1768, _728.fa_fog_c.xyz);\n        bool _1779 = _728.fa_fog_c.w > 0.5;\n        float _1780;\n        if (_1779)\n        {\n            _1780 = _1775;\n        }\n        else\n        {\n            _1780 = length(_1768);\n        }\n        float _1792 = _1780 - _728.fa_fog_b.x;\n        if (_1792 > 0.0)\n        {\n            float _1801 = _728.fa_fog.w * _1792;\n            float tau = _1801 * _1801;\n            if (_728.fa_fog_b.y > 0.0)\n            {\n                float _1817;\n                if (_1779)\n                {\n                    _1817 = in.fa_world_pos.y - (_728.fa_fog_c.y * _1775);\n                }\n                else\n                {\n                    _1817 = _728.fa_camera_pos.y;\n                }\n                float _1838 = mix(_1817, in.fa_world_pos.y, fast::clamp(_728.fa_fog_b.x / _1780, 0.0, 1.0));\n                float _1842 = in.fa_world_pos.y - _1838;\n                float _1847 = _1838 - _728.fa_fog_b.z;\n                float _1852 = in.fa_world_pos.y - _728.fa_fog_b.z;\n                bool _1855 = _1847 <= 0.0;\n                bool _1856 = !_1855;\n                bool _1862;\n                if (_1856)\n                {\n                    _1862 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1862 = _1855;\n                }\n                float _1863;\n                if (_1862)\n                {\n                    _1863 = _728.fa_fog_b.y;\n                }\n                else\n                {\n                    _1863 = _728.fa_fog_b.y * exp(-fast::min(_728.fa_fog_b.w * _1847, 80.0));\n                }\n                bool _1890;\n                if (_1856)\n                {\n                    _1890 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1890 = _1855;\n                }\n                float _1891;\n                if (_1890)\n                {\n                    _1891 = _728.fa_fog_b.y * _1847;\n                }\n                else\n                {\n                    _1891 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1847, 80.0)))) / _728.fa_fog_b.w;\n                }\n                bool _1916 = _1852 <= 0.0;\n                bool _1923;\n                if (!_1916)\n                {\n                    _1923 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1923 = _1916;\n                }\n                float _1924;\n                if (_1923)\n                {\n                    _1924 = _728.fa_fog_b.y * _1852;\n                }\n                else\n                {\n                    _1924 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1852, 80.0)))) / _728.fa_fog_b.w;\n                }\n                float _1951;\n                if (abs(_1842) < 0.001000000047497451305389404296875)\n                {\n                    _1951 = _1863;\n                }\n                else\n                {\n                    _1951 = (_1924 - _1891) / _1842;\n                }\n                tau += (_1792 * fast::max(_1951, 0.0));\n            }\n            result = mix(result, _728.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2016);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_203",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1531",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _395 = _273.world_pos;\n    fa_world_pos = _395;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_395, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1284 = fa_linear_to_srgb(param);\n        c = _1284;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1292 = fa_srgb_to_linear(param_1);\n            c = _1292;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _131;\n    if (bool(i.front_facing))\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = fast::normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = fast::normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (bool(i.front_facing))\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _728, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _728.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1323 = fa_tex_fix(param_2, param_3);\n    float4 _2119 = base_t;\n    _2119.x = _1323.x;\n    _2119.y = _1323.y;\n    _2119.z = _1323.z;\n    base_t = _2119;\n    float4 _1337 = (_2119 * _728.fa_base_color) * i.vertex_color;\n    float3 _2087 = i.world_normal;\n    if (_728.fa_maps.z > 0.5)\n    {\n        float param_4 = _728.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1369 = fa_tex_fix(param_6, param_7);\n        float3 _1372 = (_1369 * 2.0) - float3(1.0);\n        float2 _1377 = _1372.xy * _728.fa_maps.x;\n        float3 _2127 = _1372;\n        _2127.x = _1377.x;\n        _2127.y = _1377.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2127;\n        _2087 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _728.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1406 = fa_tex_fix(param_12, param_13);\n    float4 _2130 = mrt;\n    _2130.x = _1406.x;\n    _2130.y = _1406.y;\n    _2130.z = _1406.z;\n    mrt = _2130;\n    float param_14 = _728.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1445 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1472 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1337.xyz, _1337.w, _2087, fast::clamp(_728.fa_pbr.x * _1406.z, 0.0, 1.0), fast::clamp(_728.fa_pbr.y * _1406.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_728.fa_maps.y * (_1445.x - 1.0)), _728.fa_emissive.xyz + (_728.fa_model_emissive.xyz * _1472) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _728, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _728.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _203)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = _203.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_214)\n    {\n        l = fast::normalize(_203.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203.fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / float3(fast::max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / fast::max(_203.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _256 = fast::clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (_203.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_203.fa_light_dir[li].w, mix(_203.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_203.fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _203.fa_light_color[li].xyz * atten, atten, 1.0, dist, _307 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _369)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369.fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369.fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369.fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369.fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _427 = fast::max(_369.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = fast::min(_438 / fast::max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (_369.fa_shadow_bias.y > 0.0)\n    {\n        _451 = _369.fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float4 _476 = _369.fa_shadow_mat[ci] * float4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < _369.fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (_369.fa_shadow_bias.x > 0.0)\n    {\n        _529 = _369.fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((_369.fa_shadow_info[ci].x * fast::min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(_369.fa_shadow_cfg.z + 0.5);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369.fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = fast::clamp(((_369.fa_shadow_cfg.w * _427) * 0.25) / _369.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369.fa_shadow_bias.zw);\n            float4 param_6 = _369.fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_548 - (sum / cnt), 0.0) * _427) * _369.fa_shadow_cfg.w) / _369.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369.fa_shadow_bias.zw);\n        float4 param_11 = _369.fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728)\n{\n    if (_728.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(_369.fa_shadow_cfg.x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param, _369))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369.fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369.fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369.fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_369.fa_shadow_cfg.y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5, _369);\n        }\n        else\n        {\n            _847 = _369.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _369) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = fast::clamp((_755 - (fa_shadow_split_at(param_7, _369) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _203, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1, _203);\n    float3 _2072 = _1194.direction;\n    float3 _2067 = _1194.color;\n    float _2074 = _1194.attenuation;\n    float _2069 = _1194.shadow;\n    int _2077 = _1194.type;\n    if ((_2077 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2072;\n        float _1208 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, fa_world_pos);\n        _2069 = _1208;\n        _2067 = _203.fa_light_color[li].xyz * (_2074 * _1208);\n    }\n    return LightSample{ _2072, _2067, _2074, _2069, _1194._distance, _2077 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1130 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _728.fa_env_horizon.w)).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(_728.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_728.fa_env_horizon.xyz, _728.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((_728.fa_env_sky.xyz + _728.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1035 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _728, fa_env_tex, fa_env_smp) * ((f0 * _1172.x) + float3(_1172.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _369)\n{\n    if (_369.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(_369.fa_shadow_cfg.x + 0.5);\n    float _932 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param, _369);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369.fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369.fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369.fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _728 [[buffer(1)]], constant fa_lights& _203 [[buffer(2)]], constant fa_material& _1531 [[buffer(5)]], constant fa_shadows& _369 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1992 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1515 = fast::normalize(_728.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1515, short(gl_FrontFacing) };\n    Surface _1520 = fa_standard_surface(param, _728, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2015 = _1520.albedo;\n    float _2016 = _1520.alpha;\n    float3 _2017 = _1520.normal;\n    float _2018 = _1520.metallic;\n    float _2019 = _1520.roughness;\n    float _2020 = _1520.occlusion;\n    float3 _2021 = _1520.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1515, short(gl_FrontFacing) };\n    Surface param_2 = _1520;\n    surface(param_1, param_2, mask, mask_smp);\n    _2015 = param_2.albedo;\n    _2016 = param_2.alpha;\n    _2017 = param_2.normal;\n    _2018 = param_2.metallic;\n    _2019 = param_2.roughness;\n    _2020 = param_2.occlusion;\n    _2021 = param_2.emission;\n    if (param_2.alpha < _1531.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_728.fa_emissive.w > 0.5)\n    {\n        result = _2015;\n    }\n    else\n    {\n        float3 _1553 = fast::normalize(_2017);\n        float _1560 = fast::clamp(_2018, 0.0, 1.0);\n        float _1564 = fast::clamp(_2019, 0.0500000007450580596923828125, 1.0);\n        float _1568 = _1564 * _1564;\n        float _1572 = _1568 * _1568;\n        float _1577 = fast::max(dot(_1553, _1515), 9.9999997473787516355514526367188e-05);\n        float3 _1583 = _2015 * (1.0 - _1560);\n        float3 _1591 = mix(float3(0.039999999105930328369140625), _2015, float3(_1560));\n        float3 param_3 = _1553;\n        float3 lit = (fa_ambient_light(param_3, _728, fa_env_smp, fa_irr_tex) * _1583) * _2020;\n        int _1605 = int(_728.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1605)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1992;\n            LightSample _1629 = fa_light_shadowed(param_4, param_5, param_6, _203, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, in.fa_world_pos);\n            float3 _2050 = _1629.direction;\n            float _1637 = fast::max(dot(_1553, _2050), 0.0);\n            float3 _1648 = fast::normalize(_2050 + _1515);\n            float _1653 = fast::max(dot(_1553, _1648), 0.0);\n            float _1666 = ((_1653 * _1653) * (_1572 - 1.0)) + 1.0;\n            lit += (((_1583 + (((_1591 + ((float3(1.0) - _1591) * powr(1.0 - fast::max(dot(_1515, _1648), 0.0), 5.0))) * (((_1572 / ((3.1415927410125732421875 * _1666) * _1666)) * (0.5 / fast::max(mix((2.0 * _1637) * _1577, _1637 + _1577, _1568), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1637))) * _203.fa_light_color[li].xyz) * (_1637 * (_1629.attenuation * _1629.shadow)));\n        }\n        float3 param_7 = _1553;\n        float3 param_8 = _1515;\n        float3 param_9 = _1591;\n        float param_10 = _1564;\n        float3 _1736 = lit;\n        float3 _1737 = _1736 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _728, fa_env_tex, fa_env_smp) * _2020);\n        lit = _1737;\n        result = _1737;\n    }\n    float3 _1741 = result;\n    float3 _1742 = _1741 + _2021;\n    result = _1742;\n    float3 param_11 = _1742;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _369);\n    bool _1751 = _728.fa_fog.w > 0.0;\n    bool _1759;\n    if (!_1751)\n    {\n        _1759 = _728.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1759 = _1751;\n    }\n    if (_1759)\n    {\n        float3 _1768 = in.fa_world_pos - _728.fa_camera_pos.xyz;\n        float _1775 = dot(_1768, _728.fa_fog_c.xyz);\n        bool _1779 = _728.fa_fog_c.w > 0.5;\n        float _1780;\n        if (_1779)\n        {\n            _1780 = _1775;\n        }\n        else\n        {\n            _1780 = length(_1768);\n        }\n        float _1792 = _1780 - _728.fa_fog_b.x;\n        if (_1792 > 0.0)\n        {\n            float _1801 = _728.fa_fog.w * _1792;\n            float tau = _1801 * _1801;\n            if (_728.fa_fog_b.y > 0.0)\n            {\n                float _1817;\n                if (_1779)\n                {\n                    _1817 = in.fa_world_pos.y - (_728.fa_fog_c.y * _1775);\n                }\n                else\n                {\n                    _1817 = _728.fa_camera_pos.y;\n                }\n                float _1838 = mix(_1817, in.fa_world_pos.y, fast::clamp(_728.fa_fog_b.x / _1780, 0.0, 1.0));\n                float _1842 = in.fa_world_pos.y - _1838;\n                float _1847 = _1838 - _728.fa_fog_b.z;\n                float _1852 = in.fa_world_pos.y - _728.fa_fog_b.z;\n                bool _1855 = _1847 <= 0.0;\n                bool _1856 = !_1855;\n                bool _1862;\n                if (_1856)\n                {\n                    _1862 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1862 = _1855;\n                }\n                float _1863;\n                if (_1862)\n                {\n                    _1863 = _728.fa_fog_b.y;\n                }\n                else\n                {\n                    _1863 = _728.fa_fog_b.y * exp(-fast::min(_728.fa_fog_b.w * _1847, 80.0));\n                }\n                bool _1890;\n                if (_1856)\n                {\n                    _1890 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1890 = _1855;\n                }\n                float _1891;\n                if (_1890)\n                {\n                    _1891 = _728.fa_fog_b.y * _1847;\n                }\n                else\n                {\n                    _1891 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1847, 80.0)))) / _728.fa_fog_b.w;\n                }\n                bool _1916 = _1852 <= 0.0;\n                bool _1923;\n                if (!_1916)\n                {\n                    _1923 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1923 = _1916;\n                }\n                float _1924;\n                if (_1923)\n                {\n                    _1924 = _728.fa_fog_b.y * _1852;\n                }\n                else\n                {\n                    _1924 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1852, 80.0)))) / _728.fa_fog_b.w;\n                }\n                float _1951;\n                if (abs(_1842) < 0.001000000047497451305389404296875)\n                {\n                    _1951 = _1863;\n                }\n                else\n                {\n                    _1951 = (_1924 - _1891) / _1842;\n                }\n                tau += (_1792 * fast::max(_1951, 0.0));\n            }\n            result = mix(result, _728.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2016);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_203",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1531",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _608 = base_t;\n    _608.x = _237.x;\n    _608.y = _237.y;\n    _608.z = _237.z;\n    base_t = _608;\n    float4 _253 = (_608 * _225.fa_base_color) * i.vertex_color;\n    float3 _589 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _616 = _290;\n        _616.x = _295.x;\n        _616.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _616;\n        _589 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _619 = mrt;\n    _619.x = _324.x;\n    _619.y = _324.y;\n    _619.z = _324.z;\n    mrt = _619;\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    return Surface{ _253.xyz, _253.w, _589, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_365.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _392) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _454 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _536 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _536 = -_536;\n    }\n    float3 _438 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _536, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface _443 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _560 = _443.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _536, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = _443;\n    surface(param_1, param_2, mask, mask_smp);\n    _560 = param_2.normal;\n    if (param_2.alpha < _454.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _464 = fast::normalize(_560);\n    float3 _479 = fast::normalize(float3(dot(in.fa_pre_r0, _464), dot(in.fa_pre_r1, _464), dot(in.fa_pre_r2, _464)));\n    float _491 = _479.z;\n    float2 e = _479.xy / float2((abs(_479.x) + abs(_479.y)) + abs(_491));\n    if (_491 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _608 = base_t;\n    _608.x = _237.x;\n    _608.y = _237.y;\n    _608.z = _237.z;\n    base_t = _608;\n    float4 _253 = (_608 * _225.fa_base_color) * i.vertex_color;\n    float3 _589 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _616 = _290;\n        _616.x = _295.x;\n        _616.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _616;\n        _589 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _619 = mrt;\n    _619.x = _324.x;\n    _619.y = _324.y;\n    _619.z = _324.z;\n    mrt = _619;\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    return Surface{ _253.xyz, _253.w, _589, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_365.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _392) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _454 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _536 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _536 = -_536;\n    }\n    float3 _438 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _536, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface _443 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _560 = _443.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _536, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = _443;\n    surface(param_1, param_2, mask, mask_smp);\n    _560 = param_2.normal;\n    if (param_2.alpha < _454.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _464 = fast::normalize(_560);\n    float3 _479 = fast::normalize(float3(dot(in.fa_pre_r0, _464), dot(in.fa_pre_r1, _464), dot(in.fa_pre_r2, _464)));\n    float _491 = _479.z;\n    float2 e = _479.xy / float2((abs(_479.x) + abs(_479.y)) + abs(_491));\n    if (_491 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _122)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _122 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _122);\n    float3 _239 = _190.world_pos;\n    out.fa_world_pos = _239;\n    out.fa_world_normal = _190.world_normal;\n    out.fa_world_tangent = _190.world_tangent;\n    out.fa_uv = _190.uv;\n    out.fa_vertex_color = _190.color;\n    out.gl_Position = _122.fa_light_vp * float4(_239, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _542 = base_t;\n    _542.x = _237.x;\n    _542.y = _237.y;\n    _542.z = _237.z;\n    base_t = _542;\n    float4 _253 = (_542 * _225.fa_base_color) * i.vertex_color;\n    float3 _529 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _550 = _290;\n        _550.x = _295.x;\n        _550.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _550;\n        _529 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _553 = mrt;\n    _553.x = _324.x;\n    _553.y = _324.y;\n    _553.z = _324.z;\n    mrt = _553;\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    return Surface{ _253.xyz, _253.w, _529, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_365.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _392) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _454 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _476 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _476 = -_476;\n    }\n    float3 _438 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _476, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _476, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _454.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _174)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_174.fa_joint_rows[_165] * weights[i]);\n        r1 += (_174.fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174.fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _127)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _127 [[buffer(0)]], constant fa_skin& _174 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _174);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _127);\n    float3 _360 = _311.world_pos;\n    out.fa_world_pos = _360;\n    out.fa_world_normal = _311.world_normal;\n    out.fa_world_tangent = _311.world_tangent;\n    out.fa_uv = _311.uv;\n    out.fa_vertex_color = _311.color;\n    out.gl_Position = _127.fa_light_vp * float4(_360, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _542 = base_t;\n    _542.x = _237.x;\n    _542.y = _237.y;\n    _542.z = _237.z;\n    base_t = _542;\n    float4 _253 = (_542 * _225.fa_base_color) * i.vertex_color;\n    float3 _529 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _550 = _290;\n        _550.x = _295.x;\n        _550.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _550;\n        _529 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _553 = mrt;\n    _553.x = _324.x;\n    _553.y = _324.y;\n    _553.z = _324.z;\n    mrt = _553;\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    return Surface{ _253.xyz, _253.w, _529, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_365.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _392) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _454 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _476 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _476 = -_476;\n    }\n    float3 _438 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _476, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _476, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _454.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_454",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
