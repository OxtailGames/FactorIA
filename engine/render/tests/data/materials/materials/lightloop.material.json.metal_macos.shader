{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _152;\n    if (bool(i.front_facing))\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    float3 _176 = fast::normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    float3 _204 = fast::normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    float3 _207;\n    if (bool(i.front_facing))\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _749, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _749.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1504 = fa_tex_fix(param_2, param_3);\n    float4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    float4 _1518 = (_2148 * _749.fa_base_color) * i.vertex_color;\n    float3 _2116 = i.world_normal;\n    if (_749.fa_maps.z > 0.5)\n    {\n        float param_4 = _749.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1550 = fa_tex_fix(param_6, param_7);\n        float3 _1554 = (_1550 * 2.0) - float3(1.0);\n        float2 _1559 = _1554.xy * _749.fa_maps.x;\n        float3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _749.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1588 = fa_tex_fix(param_12, param_13);\n    float4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = _749.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = _749.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1654 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1518.xyz, _1518.w, _2116, fast::clamp(_749.fa_pbr.x * _1588.z, 0.0, 1.0), fast::clamp(_749.fa_pbr.y * _1588.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_749.fa_maps.y * (_1627.x - 1.0)), _749.fa_emissive.xyz + (_749.fa_model_emissive.xyz * _1654) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _749)\n{\n    return min(int(_749.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _224)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _235 = _224.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_235)\n    {\n        l = fast::normalize(_224.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _253 = _224.fa_light_pos[li].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / float3(fast::max(_255, 9.9999997473787516355514526367188e-05));\n        float _271 = _255 / fast::max(_224.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _277 = fast::clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (_224.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_224.fa_light_dir[li].w, mix(_224.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_224.fa_light_dir[li].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (_224.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _224.fa_light_color[li].xyz * atten, atten, 1.0, dist, _328 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _224, constant fa_mesh_fs_params& _749)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count(_749);\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1, _224);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _390)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = _390.fa_shadow_split.x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = _390.fa_shadow_split.y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = _390.fa_shadow_split.z;\n            }\n            else\n            {\n                _404 = _390.fa_shadow_split.w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _448 = fast::max(_390.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _453 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _459 = sqrt(1.0 - (_453 * _453));\n    float _467 = fast::min(_459 / fast::max(_453, 0.20000000298023223876953125), 4.0);\n    float _472;\n    if (_390.fa_shadow_bias.y > 0.0)\n    {\n        _472 = _390.fa_shadow_bias.y;\n    }\n    else\n    {\n        _472 = 1.5 * _390.fa_shadow_info[ci].x;\n    }\n    float4 _497 = _390.fa_shadow_mat[ci] * float4(world + (n * (_472 * _459)), 1.0);\n    float _504 = _497.x;\n    bool _507 = _504 < _390.fa_shadow_rect[ci].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > _390.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < _390.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > _390.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0;\n    }\n    float _550;\n    if (_390.fa_shadow_bias.x > 0.0)\n    {\n        _550 = _390.fa_shadow_bias.x;\n    }\n    else\n    {\n        _550 = 1.5 * _390.fa_shadow_info[ci].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0 + (0.5 * _467))) / _448);\n    float _578 = ((_390.fa_shadow_info[ci].x * fast::min(_467, 3.0)) * 0.5) / _448;\n    int _587 = int(_390.fa_shadow_cfg.z + 0.5);\n    if (_587 == 1)\n    {\n        float2 param = _497.xy;\n        float4 param_1 = _390.fa_shadow_rect[ci];\n        float _598 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = fast::clamp(((_390.fa_shadow_cfg.w * _448) * 0.25) / _390.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            float2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            float2 param_5 = _497.xy + (_642 * _390.fa_shadow_bias.zw);\n            float4 param_6 = _390.fa_shadow_rect[ci];\n            float _653 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_569 - (sum / cnt), 0.0) * _448) * _390.fa_shadow_cfg.w) / _390.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        float2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _497.xy + (_716 * _390.fa_shadow_bias.zw);\n        float4 param_11 = _390.fa_shadow_rect[ci];\n        float _727 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749)\n{\n    if (_749.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _760 = int(_390.fa_shadow_cfg.x + 0.5);\n    if (_760 < 1)\n    {\n        return 1.0;\n    }\n    float _776 = dot(world - _390.fa_shadow_eye.xyz, _390.fa_shadow_fwd.xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param, _390))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > _390.fa_shadow_split.x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > _390.fa_shadow_split.y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > _390.fa_shadow_split.z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp);\n        s = _843;\n        if (_843 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_390.fa_shadow_cfg.y > 0.0)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5, _390);\n        }\n        else\n        {\n            _868 = _390.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _887 = _390.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _390) - _868, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _898 = fast::clamp((_776 - (fa_shadow_split_at(param_7, _390) - _887)) / _887, 0.0, 1.0);\n        if (_898 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp);\n                s2 = _919;\n                if (_919 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1, _224);\n    float3 _2092 = _1242.direction;\n    float3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n        _2089 = _1256;\n        _2087 = _224.fa_light_color[li].xyz * (_2094 * _1256);\n    }\n    return LightSample{ _2092, _2087, _2094, _2089, _1242._distance, _2097 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count(_749);\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1133 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1136 = _1133.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1136 * _1136, exp2((-9.27999973297119140625) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_749.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _749.fa_env_horizon.w)).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625 * _1056;\n    return mix(mix(_749.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_749.fa_env_horizon.xyz, _749.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1056)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1086, 0.0500000007450580596923828125 + _1086, d.y))), ((_749.fa_env_sky.xyz + _749.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1056 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1175 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _749, fa_env_tex, fa_env_smp) * ((f0 * _1175.x) + float3(_1175.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _749, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, constant fa_material& _1393)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(_749); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1, _224, _749).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    float3 lit = (_749.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5)\n        {\n            _1387 = 1.0;\n        }\n        else\n        {\n            _1387 = _1393.dark;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _749, fa_env_tex, fa_env_smp) * _1393.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _390)\n{\n    if (_390.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _943 = int(_390.fa_shadow_cfg.x + 0.5);\n    float _953 = dot(world - _390.fa_shadow_eye.xyz, _390.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param, _390);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > _390.fa_shadow_split.x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > _390.fa_shadow_split.y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > _390.fa_shadow_split.z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _749 [[buffer(1)]], constant fa_lights& _224 [[buffer(2)]], constant fa_material& _1393 [[buffer(5)]], constant fa_shadows& _390 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1992 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1697 = fast::normalize(_749.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n    Surface _1702 = fa_standard_surface(param, _749, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    float3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    float3 _2029 = _1702.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    float3 result;\n    if (_749.fa_emissive.w > 0.5)\n    {\n        result = _2023;\n    }\n    else\n    {\n        float3 _1723 = _2025;\n        float3 _1724 = fast::normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2023, _2024, _1724, _2026, _2027, _2028, _2029 };\n        result = lighting(param_3, param_4, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, in.fa_world_pos, fa_env_tex, fa_env_smp, _1393);\n    }\n    float3 _1739 = result;\n    float3 _1740 = _1739 + _2029;\n    result = _1740;\n    float3 param_5 = _1740;\n    float3 param_6 = in.fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6, _390);\n    bool _1749 = _749.fa_fog.w > 0.0;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = _749.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        float3 _1766 = in.fa_world_pos - _749.fa_camera_pos.xyz;\n        float _1773 = dot(_1766, _749.fa_fog_c.xyz);\n        bool _1777 = _749.fa_fog_c.w > 0.5;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - _749.fa_fog_b.x;\n        if (_1790 > 0.0)\n        {\n            float _1799 = _749.fa_fog.w * _1790;\n            float tau = _1799 * _1799;\n            if (_749.fa_fog_b.y > 0.0)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = in.fa_world_pos.y - (_749.fa_fog_c.y * _1773);\n                }\n                else\n                {\n                    _1815 = _749.fa_camera_pos.y;\n                }\n                float _1836 = mix(_1815, in.fa_world_pos.y, fast::clamp(_749.fa_fog_b.x / _1778, 0.0, 1.0));\n                float _1840 = in.fa_world_pos.y - _1836;\n                float _1845 = _1836 - _749.fa_fog_b.z;\n                float _1850 = in.fa_world_pos.y - _749.fa_fog_b.z;\n                bool _1853 = _1845 <= 0.0;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = _749.fa_fog_b.y;\n                }\n                else\n                {\n                    _1861 = _749.fa_fog_b.y * exp(-fast::min(_749.fa_fog_b.w * _1845, 80.0));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = _749.fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1889 = (_749.fa_fog_b.y * (1.0 - exp(-fast::min(_749.fa_fog_b.w * _1845, 80.0)))) / _749.fa_fog_b.w;\n                }\n                bool _1914 = _1850 <= 0.0;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = _749.fa_fog_b.y * _1850;\n                }\n                else\n                {\n                    _1922 = (_749.fa_fog_b.y * (1.0 - exp(-fast::min(_749.fa_fog_b.w * _1850, 80.0)))) / _749.fa_fog_b.w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * fast::max(_1949, 0.0));\n            }\n            result = mix(result, _749.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2024);\n    return out;\n}\n\n",
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
            "inst_name": "_224",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 6,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _152;\n    if (bool(i.front_facing))\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    float3 _176 = fast::normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    float3 _204 = fast::normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    float3 _207;\n    if (bool(i.front_facing))\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _749, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _749.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1504 = fa_tex_fix(param_2, param_3);\n    float4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    float4 _1518 = (_2148 * _749.fa_base_color) * i.vertex_color;\n    float3 _2116 = i.world_normal;\n    if (_749.fa_maps.z > 0.5)\n    {\n        float param_4 = _749.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1550 = fa_tex_fix(param_6, param_7);\n        float3 _1554 = (_1550 * 2.0) - float3(1.0);\n        float2 _1559 = _1554.xy * _749.fa_maps.x;\n        float3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _749.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1588 = fa_tex_fix(param_12, param_13);\n    float4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = _749.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = _749.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1654 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1518.xyz, _1518.w, _2116, fast::clamp(_749.fa_pbr.x * _1588.z, 0.0, 1.0), fast::clamp(_749.fa_pbr.y * _1588.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_749.fa_maps.y * (_1627.x - 1.0)), _749.fa_emissive.xyz + (_749.fa_model_emissive.xyz * _1654) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _749)\n{\n    return min(int(_749.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _224)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _235 = _224.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_235)\n    {\n        l = fast::normalize(_224.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _253 = _224.fa_light_pos[li].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / float3(fast::max(_255, 9.9999997473787516355514526367188e-05));\n        float _271 = _255 / fast::max(_224.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _277 = fast::clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (_224.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_224.fa_light_dir[li].w, mix(_224.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_224.fa_light_dir[li].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (_224.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _224.fa_light_color[li].xyz * atten, atten, 1.0, dist, _328 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _224, constant fa_mesh_fs_params& _749)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count(_749);\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1, _224);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _390)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = _390.fa_shadow_split.x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = _390.fa_shadow_split.y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = _390.fa_shadow_split.z;\n            }\n            else\n            {\n                _404 = _390.fa_shadow_split.w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _448 = fast::max(_390.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _453 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _459 = sqrt(1.0 - (_453 * _453));\n    float _467 = fast::min(_459 / fast::max(_453, 0.20000000298023223876953125), 4.0);\n    float _472;\n    if (_390.fa_shadow_bias.y > 0.0)\n    {\n        _472 = _390.fa_shadow_bias.y;\n    }\n    else\n    {\n        _472 = 1.5 * _390.fa_shadow_info[ci].x;\n    }\n    float4 _497 = _390.fa_shadow_mat[ci] * float4(world + (n * (_472 * _459)), 1.0);\n    float _504 = _497.x;\n    bool _507 = _504 < _390.fa_shadow_rect[ci].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > _390.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < _390.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > _390.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0;\n    }\n    float _550;\n    if (_390.fa_shadow_bias.x > 0.0)\n    {\n        _550 = _390.fa_shadow_bias.x;\n    }\n    else\n    {\n        _550 = 1.5 * _390.fa_shadow_info[ci].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0 + (0.5 * _467))) / _448);\n    float _578 = ((_390.fa_shadow_info[ci].x * fast::min(_467, 3.0)) * 0.5) / _448;\n    int _587 = int(_390.fa_shadow_cfg.z + 0.5);\n    if (_587 == 1)\n    {\n        float2 param = _497.xy;\n        float4 param_1 = _390.fa_shadow_rect[ci];\n        float _598 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = fast::clamp(((_390.fa_shadow_cfg.w * _448) * 0.25) / _390.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            float2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            float2 param_5 = _497.xy + (_642 * _390.fa_shadow_bias.zw);\n            float4 param_6 = _390.fa_shadow_rect[ci];\n            float _653 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_569 - (sum / cnt), 0.0) * _448) * _390.fa_shadow_cfg.w) / _390.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        float2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _497.xy + (_716 * _390.fa_shadow_bias.zw);\n        float4 param_11 = _390.fa_shadow_rect[ci];\n        float _727 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749)\n{\n    if (_749.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _760 = int(_390.fa_shadow_cfg.x + 0.5);\n    if (_760 < 1)\n    {\n        return 1.0;\n    }\n    float _776 = dot(world - _390.fa_shadow_eye.xyz, _390.fa_shadow_fwd.xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param, _390))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > _390.fa_shadow_split.x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > _390.fa_shadow_split.y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > _390.fa_shadow_split.z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp);\n        s = _843;\n        if (_843 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_390.fa_shadow_cfg.y > 0.0)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5, _390);\n        }\n        else\n        {\n            _868 = _390.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _887 = _390.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _390) - _868, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _898 = fast::clamp((_776 - (fa_shadow_split_at(param_7, _390) - _887)) / _887, 0.0, 1.0);\n        if (_898 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp);\n                s2 = _919;\n                if (_919 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1, _224);\n    float3 _2092 = _1242.direction;\n    float3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n        _2089 = _1256;\n        _2087 = _224.fa_light_color[li].xyz * (_2094 * _1256);\n    }\n    return LightSample{ _2092, _2087, _2094, _2089, _1242._distance, _2097 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count(_749);\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1133 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1136 = _1133.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1136 * _1136, exp2((-9.27999973297119140625) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_749.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _749.fa_env_horizon.w)).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625 * _1056;\n    return mix(mix(_749.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_749.fa_env_horizon.xyz, _749.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1056)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1086, 0.0500000007450580596923828125 + _1086, d.y))), ((_749.fa_env_sky.xyz + _749.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1056 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1175 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _749, fa_env_tex, fa_env_smp) * ((f0 * _1175.x) + float3(_1175.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _749, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 param = fast::normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = mix(float3(0.039999999105930328369140625), s.albedo, float3(fast::clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3, _749, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_lights& _224, thread float4& gl_FragCoord, constant fa_shadows& _390, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _749, thread float3& fa_world_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, constant fa_material& _1393)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(_749); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1, _224, _749).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    float3 lit = (_749.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, fa_world_pos);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5)\n        {\n            _1387 = 1.0;\n        }\n        else\n        {\n            _1387 = _1393.dark;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _749, fa_env_tex, fa_env_smp) * _1393.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _390)\n{\n    if (_390.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _943 = int(_390.fa_shadow_cfg.x + 0.5);\n    float _953 = dot(world - _390.fa_shadow_eye.xyz, _390.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param, _390);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > _390.fa_shadow_split.x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > _390.fa_shadow_split.y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > _390.fa_shadow_split.z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _749 [[buffer(1)]], constant fa_lights& _224 [[buffer(2)]], constant fa_material& _1393 [[buffer(5)]], constant fa_shadows& _390 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1992 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1697 = fast::normalize(_749.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n    Surface _1702 = fa_standard_surface(param, _749, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    float3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    float3 _2029 = _1702.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    float3 result;\n    if (_749.fa_emissive.w > 0.5)\n    {\n        result = _2023;\n    }\n    else\n    {\n        float3 _1723 = _2025;\n        float3 _1724 = fast::normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _1992, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1697, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2023, _2024, _1724, _2026, _2027, _2028, _2029 };\n        result = lighting(param_3, param_4, _224, gl_FragCoord, _390, fa_shadow_tex, fa_shadow_smp, _749, in.fa_world_pos, fa_env_tex, fa_env_smp, _1393);\n    }\n    float3 _1739 = result;\n    float3 _1740 = _1739 + _2029;\n    result = _1740;\n    float3 param_5 = _1740;\n    float3 param_6 = in.fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6, _390);\n    bool _1749 = _749.fa_fog.w > 0.0;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = _749.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        float3 _1766 = in.fa_world_pos - _749.fa_camera_pos.xyz;\n        float _1773 = dot(_1766, _749.fa_fog_c.xyz);\n        bool _1777 = _749.fa_fog_c.w > 0.5;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - _749.fa_fog_b.x;\n        if (_1790 > 0.0)\n        {\n            float _1799 = _749.fa_fog.w * _1790;\n            float tau = _1799 * _1799;\n            if (_749.fa_fog_b.y > 0.0)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = in.fa_world_pos.y - (_749.fa_fog_c.y * _1773);\n                }\n                else\n                {\n                    _1815 = _749.fa_camera_pos.y;\n                }\n                float _1836 = mix(_1815, in.fa_world_pos.y, fast::clamp(_749.fa_fog_b.x / _1778, 0.0, 1.0));\n                float _1840 = in.fa_world_pos.y - _1836;\n                float _1845 = _1836 - _749.fa_fog_b.z;\n                float _1850 = in.fa_world_pos.y - _749.fa_fog_b.z;\n                bool _1853 = _1845 <= 0.0;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = _749.fa_fog_b.y;\n                }\n                else\n                {\n                    _1861 = _749.fa_fog_b.y * exp(-fast::min(_749.fa_fog_b.w * _1845, 80.0));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = _749.fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1889 = (_749.fa_fog_b.y * (1.0 - exp(-fast::min(_749.fa_fog_b.w * _1845, 80.0)))) / _749.fa_fog_b.w;\n                }\n                bool _1914 = _1850 <= 0.0;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = _749.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = _749.fa_fog_b.y * _1850;\n                }\n                else\n                {\n                    _1922 = (_749.fa_fog_b.y * (1.0 - exp(-fast::min(_749.fa_fog_b.w * _1850, 80.0)))) / _749.fa_fog_b.w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * fast::max(_1949, 0.0));\n            }\n            result = mix(result, _749.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2024);\n    return out;\n}\n\n",
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
            "inst_name": "_224",
            "msl_buffer_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
            "msl_buffer_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 6,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    float4 _241 = (_589 * _213.fa_base_color) * i.vertex_color;\n    float3 _570 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _570, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _517 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _517, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _517, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    float4 _241 = (_589 * _213.fa_base_color) * i.vertex_color;\n    float3 _570 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _570, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _517 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _517, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _517, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
