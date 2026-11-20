{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    },
    {
      "name": "points",
      "binding": 1,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _182)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _62 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra, constant fa_mesh_vs_params& _182, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _182);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _182.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _182 [[buffer(0)]], constant fa_inst_base& _252 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _252.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, fa_vs_extra, _182, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1287 = fa_linear_to_srgb(param);\n        c = _1287;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1295 = fa_srgb_to_linear(param_1);\n            c = _1295;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _131;\n    if (bool(i.front_facing))\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = fast::normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = fast::normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (bool(i.front_facing))\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _728, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _728.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1326 = fa_tex_fix(param_2, param_3);\n    float4 _2117 = base_t;\n    _2117.x = _1326.x;\n    _2117.y = _1326.y;\n    _2117.z = _1326.z;\n    base_t = _2117;\n    float4 _1340 = (_2117 * _728.fa_base_color) * i.vertex_color;\n    float3 _2085 = i.world_normal;\n    if (_728.fa_maps.z > 0.5)\n    {\n        float param_4 = _728.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1372 = fa_tex_fix(param_6, param_7);\n        float3 _1376 = (_1372 * 2.0) - float3(1.0);\n        float2 _1381 = _1376.xy * _728.fa_maps.x;\n        float3 _2125 = _1376;\n        _2125.x = _1381.x;\n        _2125.y = _1381.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2125;\n        _2085 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _728.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1410 = fa_tex_fix(param_12, param_13);\n    float4 _2128 = mrt;\n    _2128.x = _1410.x;\n    _2128.y = _1410.y;\n    _2128.z = _1410.z;\n    mrt = _2128;\n    float param_14 = _728.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1449 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1476 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1340.xyz, _1340.w, _2085, fast::clamp(_728.fa_pbr.x * _1410.z, 0.0, 1.0), fast::clamp(_728.fa_pbr.y * _1410.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_728.fa_maps.y * (_1449.x - 1.0)), _728.fa_emissive.xyz + (_728.fa_model_emissive.xyz * _1476) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _728, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _728.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _203)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = _203.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_214)\n    {\n        l = fast::normalize(_203.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203.fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / float3(fast::max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / fast::max(_203.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _256 = fast::clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (_203.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_203.fa_light_dir[li].w, mix(_203.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_203.fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _203.fa_light_color[li].xyz * atten, atten, 1.0, dist, _307 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _369)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369.fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369.fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369.fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369.fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _427 = fast::max(_369.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = fast::min(_438 / fast::max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (_369.fa_shadow_bias.y > 0.0)\n    {\n        _451 = _369.fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float4 _476 = _369.fa_shadow_mat[ci] * float4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < _369.fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (_369.fa_shadow_bias.x > 0.0)\n    {\n        _529 = _369.fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((_369.fa_shadow_info[ci].x * fast::min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(_369.fa_shadow_cfg.z + 0.5);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369.fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = fast::clamp(((_369.fa_shadow_cfg.w * _427) * 0.25) / _369.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369.fa_shadow_bias.zw);\n            float4 param_6 = _369.fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_548 - (sum / cnt), 0.0) * _427) * _369.fa_shadow_cfg.w) / _369.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369.fa_shadow_bias.zw);\n        float4 param_11 = _369.fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728)\n{\n    if (_728.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(_369.fa_shadow_cfg.x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param, _369))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369.fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369.fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369.fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_369.fa_shadow_cfg.y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5, _369);\n        }\n        else\n        {\n            _847 = _369.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _369) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = fast::clamp((_755 - (fa_shadow_split_at(param_7, _369) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _203, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1, _203);\n    float3 _2070 = _1194.direction;\n    float3 _2065 = _1194.color;\n    float _2072 = _1194.attenuation;\n    float _2067 = _1194.shadow;\n    int _2075 = _1194.type;\n    if ((_2075 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2070;\n        float _1208 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, fa_world_pos);\n        _2067 = _1208;\n        _2065 = _203.fa_light_color[li].xyz * (_2072 * _1208);\n    }\n    return LightSample{ _2070, _2065, _2072, _2067, _1194._distance, _2075 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1130 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _728.fa_env_horizon.w)).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(_728.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_728.fa_env_horizon.xyz, _728.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((_728.fa_env_sky.xyz + _728.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1035 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _728, fa_env_tex, fa_env_smp) * ((f0 * _1172.x) + float3(_1172.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _369)\n{\n    if (_369.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(_369.fa_shadow_cfg.x + 0.5);\n    float _932 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param, _369);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369.fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369.fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369.fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _728 [[buffer(1)]], constant fa_lights& _203 [[buffer(2)]], constant fa_shadows& _369 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1990 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1990 = -_1990;\n    }\n    float3 _1519 = fast::normalize(_728.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1990, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1519, short(gl_FrontFacing) };\n    Surface _1524 = fa_standard_surface(param, _728, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2013 = _1524.albedo;\n    float _2014 = _1524.alpha;\n    float3 _2015 = _1524.normal;\n    float _2016 = _1524.metallic;\n    float _2017 = _1524.roughness;\n    float _2018 = _1524.occlusion;\n    float3 _2019 = _1524.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1990, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1519, short(gl_FrontFacing) };\n    Surface param_2 = _1524;\n    surface(param_1, param_2, points);\n    _2013 = param_2.albedo;\n    _2014 = param_2.alpha;\n    _2015 = param_2.normal;\n    _2016 = param_2.metallic;\n    _2017 = param_2.roughness;\n    _2018 = param_2.occlusion;\n    _2019 = param_2.emission;\n    float3 result;\n    if (_728.fa_emissive.w > 0.5)\n    {\n        result = _2013;\n    }\n    else\n    {\n        float3 _1546 = fast::normalize(_2015);\n        float _1553 = fast::clamp(_2016, 0.0, 1.0);\n        float _1557 = fast::clamp(_2017, 0.0500000007450580596923828125, 1.0);\n        float _1561 = _1557 * _1557;\n        float _1565 = _1561 * _1561;\n        float _1570 = fast::max(dot(_1546, _1519), 9.9999997473787516355514526367188e-05);\n        float3 _1576 = _2013 * (1.0 - _1553);\n        float3 _1584 = mix(float3(0.039999999105930328369140625), _2013, float3(_1553));\n        float3 param_3 = _1546;\n        float3 lit = (fa_ambient_light(param_3, _728, fa_env_smp, fa_irr_tex) * _1576) * _2018;\n        int _1598 = int(_728.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1598)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1990;\n            LightSample _1622 = fa_light_shadowed(param_4, param_5, param_6, _203, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, in.fa_world_pos);\n            float3 _2048 = _1622.direction;\n            float _1630 = fast::max(dot(_1546, _2048), 0.0);\n            float3 _1641 = fast::normalize(_2048 + _1519);\n            float _1646 = fast::max(dot(_1546, _1641), 0.0);\n            float _1659 = ((_1646 * _1646) * (_1565 - 1.0)) + 1.0;\n            lit += (((_1576 + (((_1584 + ((float3(1.0) - _1584) * powr(1.0 - fast::max(dot(_1519, _1641), 0.0), 5.0))) * (((_1565 / ((3.1415927410125732421875 * _1659) * _1659)) * (0.5 / fast::max(mix((2.0 * _1630) * _1570, _1630 + _1570, _1561), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1630))) * _203.fa_light_color[li].xyz) * (_1630 * (_1622.attenuation * _1622.shadow)));\n        }\n        float3 param_7 = _1546;\n        float3 param_8 = _1519;\n        float3 param_9 = _1584;\n        float param_10 = _1557;\n        float3 _1729 = lit;\n        float3 _1730 = _1729 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _728, fa_env_tex, fa_env_smp) * _2018);\n        lit = _1730;\n        result = _1730;\n    }\n    float3 _1734 = result;\n    float3 _1735 = _1734 + _2019;\n    result = _1735;\n    float3 param_11 = _1735;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _369);\n    bool _1744 = _728.fa_fog.w > 0.0;\n    bool _1752;\n    if (!_1744)\n    {\n        _1752 = _728.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1752 = _1744;\n    }\n    if (_1752)\n    {\n        float3 _1761 = in.fa_world_pos - _728.fa_camera_pos.xyz;\n        float _1768 = dot(_1761, _728.fa_fog_c.xyz);\n        bool _1772 = _728.fa_fog_c.w > 0.5;\n        float _1773;\n        if (_1772)\n        {\n            _1773 = _1768;\n        }\n        else\n        {\n            _1773 = length(_1761);\n        }\n        float _1785 = _1773 - _728.fa_fog_b.x;\n        if (_1785 > 0.0)\n        {\n            float _1794 = _728.fa_fog.w * _1785;\n            float tau = _1794 * _1794;\n            if (_728.fa_fog_b.y > 0.0)\n            {\n                float _1810;\n                if (_1772)\n                {\n                    _1810 = in.fa_world_pos.y - (_728.fa_fog_c.y * _1768);\n                }\n                else\n                {\n                    _1810 = _728.fa_camera_pos.y;\n                }\n                float _1831 = mix(_1810, in.fa_world_pos.y, fast::clamp(_728.fa_fog_b.x / _1773, 0.0, 1.0));\n                float _1835 = in.fa_world_pos.y - _1831;\n                float _1840 = _1831 - _728.fa_fog_b.z;\n                float _1845 = in.fa_world_pos.y - _728.fa_fog_b.z;\n                bool _1848 = _1840 <= 0.0;\n                bool _1849 = !_1848;\n                bool _1855;\n                if (_1849)\n                {\n                    _1855 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1855 = _1848;\n                }\n                float _1856;\n                if (_1855)\n                {\n                    _1856 = _728.fa_fog_b.y;\n                }\n                else\n                {\n                    _1856 = _728.fa_fog_b.y * exp(-fast::min(_728.fa_fog_b.w * _1840, 80.0));\n                }\n                bool _1883;\n                if (_1849)\n                {\n                    _1883 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1883 = _1848;\n                }\n                float _1884;\n                if (_1883)\n                {\n                    _1884 = _728.fa_fog_b.y * _1840;\n                }\n                else\n                {\n                    _1884 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1840, 80.0)))) / _728.fa_fog_b.w;\n                }\n                bool _1909 = _1845 <= 0.0;\n                bool _1916;\n                if (!_1909)\n                {\n                    _1916 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1916 = _1909;\n                }\n                float _1917;\n                if (_1916)\n                {\n                    _1917 = _728.fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1917 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1845, 80.0)))) / _728.fa_fog_b.w;\n                }\n                float _1944;\n                if (abs(_1835) < 0.001000000047497451305389404296875)\n                {\n                    _1944 = _1856;\n                }\n                else\n                {\n                    _1944 = (_1917 - _1884) / _1835;\n                }\n                tau += (_1785 * fast::max(_1944, 0.0));\n            }\n            result = mix(result, _728.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2014);\n    return out;\n}\n\n",
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
            "inst_name": "_182",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_252",
            "msl_buffer_n": 6
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _231)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_231.fa_joint_rows[_222] * weights[i]);\n        r1 += (_231.fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231.fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _187)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _67 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra, constant fa_mesh_vs_params& _187, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _187);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _187.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _187 [[buffer(0)]], constant fa_skin& _231 [[buffer(3)]], constant fa_inst_base& _364 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _364.fa_base_model * fa_skin_matrix(param, param_1, _231);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, fa_vs_extra, _187, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1287 = fa_linear_to_srgb(param);\n        c = _1287;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1295 = fa_srgb_to_linear(param_1);\n            c = _1295;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _131;\n    if (bool(i.front_facing))\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = fast::normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = fast::normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (bool(i.front_facing))\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _728, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _728.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1326 = fa_tex_fix(param_2, param_3);\n    float4 _2117 = base_t;\n    _2117.x = _1326.x;\n    _2117.y = _1326.y;\n    _2117.z = _1326.z;\n    base_t = _2117;\n    float4 _1340 = (_2117 * _728.fa_base_color) * i.vertex_color;\n    float3 _2085 = i.world_normal;\n    if (_728.fa_maps.z > 0.5)\n    {\n        float param_4 = _728.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1372 = fa_tex_fix(param_6, param_7);\n        float3 _1376 = (_1372 * 2.0) - float3(1.0);\n        float2 _1381 = _1376.xy * _728.fa_maps.x;\n        float3 _2125 = _1376;\n        _2125.x = _1381.x;\n        _2125.y = _1381.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2125;\n        _2085 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _728.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1410 = fa_tex_fix(param_12, param_13);\n    float4 _2128 = mrt;\n    _2128.x = _1410.x;\n    _2128.y = _1410.y;\n    _2128.z = _1410.z;\n    mrt = _2128;\n    float param_14 = _728.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1449 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1476 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1340.xyz, _1340.w, _2085, fast::clamp(_728.fa_pbr.x * _1410.z, 0.0, 1.0), fast::clamp(_728.fa_pbr.y * _1410.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_728.fa_maps.y * (_1449.x - 1.0)), _728.fa_emissive.xyz + (_728.fa_model_emissive.xyz * _1476) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _728, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _728.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _203)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _214 = _203.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_214)\n    {\n        l = fast::normalize(_203.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203.fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / float3(fast::max(_234, 9.9999997473787516355514526367188e-05));\n        float _250 = _234 / fast::max(_203.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _256 = fast::clamp(1.0 - (_250 * _250), 0.0, 1.0);\n        atten = _256 * _256;\n        if (_203.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_203.fa_light_dir[li].w, mix(_203.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_203.fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _203.fa_light_color[li].xyz * atten, atten, 1.0, dist, _307 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _369)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369.fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369.fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369.fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369.fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    float _427 = fast::max(_369.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _438 = sqrt(1.0 - (_432 * _432));\n    float _446 = fast::min(_438 / fast::max(_432, 0.20000000298023223876953125), 4.0);\n    float _451;\n    if (_369.fa_shadow_bias.y > 0.0)\n    {\n        _451 = _369.fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float4 _476 = _369.fa_shadow_mat[ci] * float4(world + (n * (_451 * _438)), 1.0);\n    float _483 = _476.x;\n    bool _486 = _483 < _369.fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0;\n    }\n    float _529;\n    if (_369.fa_shadow_bias.x > 0.0)\n    {\n        _529 = _369.fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5 * _369.fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0 + (0.5 * _446))) / _427);\n    float _557 = ((_369.fa_shadow_info[ci].x * fast::min(_446, 3.0)) * 0.5) / _427;\n    int _566 = int(_369.fa_shadow_cfg.z + 0.5);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369.fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1, fa_shadow_tex, fa_shadow_smp);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = fast::clamp(((_369.fa_shadow_cfg.w * _427) * 0.25) / _369.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369.fa_shadow_bias.zw);\n            float4 param_6 = _369.fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6, fa_shadow_tex, fa_shadow_smp);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_548 - (sum / cnt), 0.0) * _427) * _369.fa_shadow_cfg.w) / _369.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369.fa_shadow_bias.zw);\n        float4 param_11 = _369.fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11, fa_shadow_tex, fa_shadow_smp);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728)\n{\n    if (_728.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _739 = int(_369.fa_shadow_cfg.x + 0.5);\n    if (_739 < 1)\n    {\n        return 1.0;\n    }\n    float _755 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param, _369))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369.fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369.fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369.fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n        s = _822;\n        if (_822 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_369.fa_shadow_cfg.y > 0.0)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5, _369);\n        }\n        else\n        {\n            _847 = _369.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _369) - _847, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _877 = fast::clamp((_755 - (fa_shadow_split_at(param_7, _369) - _866)) / _866, 0.0, 1.0);\n        if (_877 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp);\n                s2 = _898;\n                if (_898 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _203, thread float4& gl_FragCoord, constant fa_shadows& _369, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _728, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1, _203);\n    float3 _2070 = _1194.direction;\n    float3 _2065 = _1194.color;\n    float _2072 = _1194.attenuation;\n    float _2067 = _1194.shadow;\n    int _2075 = _1194.type;\n    if ((_2075 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2070;\n        float _1208 = fa_shadow_factor(param_2, param_3, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, fa_world_pos);\n        _2067 = _1208;\n        _2065 = _203.fa_light_color[li].xyz * (_2072 * _1208);\n    }\n    return LightSample{ _2070, _2065, _2072, _2067, _1194._distance, _2075 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1130 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1133 * _1133, exp2((-9.27999973297119140625) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_728.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _728.fa_env_horizon.w)).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625 * _1035;\n    return mix(mix(_728.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_728.fa_env_horizon.xyz, _728.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1035)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1065, 0.0500000007450580596923828125 + _1065, d.y))), ((_728.fa_env_sky.xyz + _728.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1035 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _728, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _728, fa_env_tex, fa_env_smp) * ((f0 * _1172.x) + float3(_1172.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _369)\n{\n    if (_369.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _922 = int(_369.fa_shadow_cfg.x + 0.5);\n    float _932 = dot(world - _369.fa_shadow_eye.xyz, _369.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param, _369);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369.fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369.fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369.fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _728 [[buffer(1)]], constant fa_lights& _203 [[buffer(2)]], constant fa_shadows& _369 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1990 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1990 = -_1990;\n    }\n    float3 _1519 = fast::normalize(_728.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1990, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1519, short(gl_FrontFacing) };\n    Surface _1524 = fa_standard_surface(param, _728, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2013 = _1524.albedo;\n    float _2014 = _1524.alpha;\n    float3 _2015 = _1524.normal;\n    float _2016 = _1524.metallic;\n    float _2017 = _1524.roughness;\n    float _2018 = _1524.occlusion;\n    float3 _2019 = _1524.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1990, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1519, short(gl_FrontFacing) };\n    Surface param_2 = _1524;\n    surface(param_1, param_2, points);\n    _2013 = param_2.albedo;\n    _2014 = param_2.alpha;\n    _2015 = param_2.normal;\n    _2016 = param_2.metallic;\n    _2017 = param_2.roughness;\n    _2018 = param_2.occlusion;\n    _2019 = param_2.emission;\n    float3 result;\n    if (_728.fa_emissive.w > 0.5)\n    {\n        result = _2013;\n    }\n    else\n    {\n        float3 _1546 = fast::normalize(_2015);\n        float _1553 = fast::clamp(_2016, 0.0, 1.0);\n        float _1557 = fast::clamp(_2017, 0.0500000007450580596923828125, 1.0);\n        float _1561 = _1557 * _1557;\n        float _1565 = _1561 * _1561;\n        float _1570 = fast::max(dot(_1546, _1519), 9.9999997473787516355514526367188e-05);\n        float3 _1576 = _2013 * (1.0 - _1553);\n        float3 _1584 = mix(float3(0.039999999105930328369140625), _2013, float3(_1553));\n        float3 param_3 = _1546;\n        float3 lit = (fa_ambient_light(param_3, _728, fa_env_smp, fa_irr_tex) * _1576) * _2018;\n        int _1598 = int(_728.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1598)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1990;\n            LightSample _1622 = fa_light_shadowed(param_4, param_5, param_6, _203, gl_FragCoord, _369, fa_shadow_tex, fa_shadow_smp, _728, in.fa_world_pos);\n            float3 _2048 = _1622.direction;\n            float _1630 = fast::max(dot(_1546, _2048), 0.0);\n            float3 _1641 = fast::normalize(_2048 + _1519);\n            float _1646 = fast::max(dot(_1546, _1641), 0.0);\n            float _1659 = ((_1646 * _1646) * (_1565 - 1.0)) + 1.0;\n            lit += (((_1576 + (((_1584 + ((float3(1.0) - _1584) * powr(1.0 - fast::max(dot(_1519, _1641), 0.0), 5.0))) * (((_1565 / ((3.1415927410125732421875 * _1659) * _1659)) * (0.5 / fast::max(mix((2.0 * _1630) * _1570, _1630 + _1570, _1561), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1630))) * _203.fa_light_color[li].xyz) * (_1630 * (_1622.attenuation * _1622.shadow)));\n        }\n        float3 param_7 = _1546;\n        float3 param_8 = _1519;\n        float3 param_9 = _1584;\n        float param_10 = _1557;\n        float3 _1729 = lit;\n        float3 _1730 = _1729 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _728, fa_env_tex, fa_env_smp) * _2018);\n        lit = _1730;\n        result = _1730;\n    }\n    float3 _1734 = result;\n    float3 _1735 = _1734 + _2019;\n    result = _1735;\n    float3 param_11 = _1735;\n    float3 param_12 = in.fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12, _369);\n    bool _1744 = _728.fa_fog.w > 0.0;\n    bool _1752;\n    if (!_1744)\n    {\n        _1752 = _728.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1752 = _1744;\n    }\n    if (_1752)\n    {\n        float3 _1761 = in.fa_world_pos - _728.fa_camera_pos.xyz;\n        float _1768 = dot(_1761, _728.fa_fog_c.xyz);\n        bool _1772 = _728.fa_fog_c.w > 0.5;\n        float _1773;\n        if (_1772)\n        {\n            _1773 = _1768;\n        }\n        else\n        {\n            _1773 = length(_1761);\n        }\n        float _1785 = _1773 - _728.fa_fog_b.x;\n        if (_1785 > 0.0)\n        {\n            float _1794 = _728.fa_fog.w * _1785;\n            float tau = _1794 * _1794;\n            if (_728.fa_fog_b.y > 0.0)\n            {\n                float _1810;\n                if (_1772)\n                {\n                    _1810 = in.fa_world_pos.y - (_728.fa_fog_c.y * _1768);\n                }\n                else\n                {\n                    _1810 = _728.fa_camera_pos.y;\n                }\n                float _1831 = mix(_1810, in.fa_world_pos.y, fast::clamp(_728.fa_fog_b.x / _1773, 0.0, 1.0));\n                float _1835 = in.fa_world_pos.y - _1831;\n                float _1840 = _1831 - _728.fa_fog_b.z;\n                float _1845 = in.fa_world_pos.y - _728.fa_fog_b.z;\n                bool _1848 = _1840 <= 0.0;\n                bool _1849 = !_1848;\n                bool _1855;\n                if (_1849)\n                {\n                    _1855 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1855 = _1848;\n                }\n                float _1856;\n                if (_1855)\n                {\n                    _1856 = _728.fa_fog_b.y;\n                }\n                else\n                {\n                    _1856 = _728.fa_fog_b.y * exp(-fast::min(_728.fa_fog_b.w * _1840, 80.0));\n                }\n                bool _1883;\n                if (_1849)\n                {\n                    _1883 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1883 = _1848;\n                }\n                float _1884;\n                if (_1883)\n                {\n                    _1884 = _728.fa_fog_b.y * _1840;\n                }\n                else\n                {\n                    _1884 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1840, 80.0)))) / _728.fa_fog_b.w;\n                }\n                bool _1909 = _1845 <= 0.0;\n                bool _1916;\n                if (!_1909)\n                {\n                    _1916 = _728.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1916 = _1909;\n                }\n                float _1917;\n                if (_1916)\n                {\n                    _1917 = _728.fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1917 = (_728.fa_fog_b.y * (1.0 - exp(-fast::min(_728.fa_fog_b.w * _1845, 80.0)))) / _728.fa_fog_b.w;\n                }\n                float _1944;\n                if (abs(_1835) < 0.001000000047497451305389404296875)\n                {\n                    _1944 = _1856;\n                }\n                else\n                {\n                    _1944 = (_1917 - _1884) / _1835;\n                }\n                tau += (_1785 * fast::max(_1944, 0.0));\n            }\n            result = mix(result, _728.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2014);\n    return out;\n}\n\n",
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
            "inst_name": "_187",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_364",
            "msl_buffer_n": 6
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _182)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _62 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra, constant fa_mesh_vs_params& _182, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _182);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    float4 _224 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_182.fa_light_vp * _224).z;\n    fa_pre_r0 = float3(_182.fa_light_vp[0].x, _182.fa_light_vp[1].x, _182.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_182.fa_light_vp[0].y, _182.fa_light_vp[1].y, _182.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_182.fa_light_vp[0].z, _182.fa_light_vp[1].z, _182.fa_light_vp[2].z);\n    gl_Position = _182.fa_view_proj * _224;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _182 [[buffer(0)]], constant fa_inst_base& _286 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _286.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, fa_vs_extra, _182, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _606 = base_t;\n    _606.x = _242.x;\n    _606.y = _242.y;\n    _606.z = _242.z;\n    base_t = _606;\n    float4 _257 = (_606 * _231.fa_base_color) * i.vertex_color;\n    float3 _587 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _614 = _294;\n        _614.x = _299.x;\n        _614.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _614;\n        _587 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _617 = mrt;\n    _617.x = _328.x;\n    _617.y = _328.y;\n    _617.z = _328.z;\n    mrt = _617;\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    return Surface{ _257.xyz, _257.w, _587, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_369.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _396) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _534 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _534 = -_534;\n    }\n    float3 _442 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _534, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _442, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _534, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _442, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _457 = fast::normalize(param_2.normal);\n    float3 _472 = fast::normalize(float3(dot(in.fa_pre_r0, _457), dot(in.fa_pre_r1, _457), dot(in.fa_pre_r2, _457)));\n    float _484 = _472.z;\n    float2 e = _472.xy / float2((abs(_472.x) + abs(_472.y)) + abs(_484));\n    if (_484 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_182",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_286",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _231)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_231.fa_joint_rows[_222] * weights[i]);\n        r1 += (_231.fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231.fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _187)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _67 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra, constant fa_mesh_vs_params& _187, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _187);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    float4 _336 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_187.fa_light_vp * _336).z;\n    fa_pre_r0 = float3(_187.fa_light_vp[0].x, _187.fa_light_vp[1].x, _187.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_187.fa_light_vp[0].y, _187.fa_light_vp[1].y, _187.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_187.fa_light_vp[0].z, _187.fa_light_vp[1].z, _187.fa_light_vp[2].z);\n    gl_Position = _187.fa_view_proj * _336;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _187 [[buffer(0)]], constant fa_skin& _231 [[buffer(3)]], constant fa_inst_base& _398 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _398.fa_base_model * fa_skin_matrix(param, param_1, _231);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, fa_vs_extra, _187, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _606 = base_t;\n    _606.x = _242.x;\n    _606.y = _242.y;\n    _606.z = _242.z;\n    base_t = _606;\n    float4 _257 = (_606 * _231.fa_base_color) * i.vertex_color;\n    float3 _587 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _614 = _294;\n        _614.x = _299.x;\n        _614.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _614;\n        _587 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _617 = mrt;\n    _617.x = _328.x;\n    _617.y = _328.y;\n    _617.z = _328.z;\n    mrt = _617;\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    return Surface{ _257.xyz, _257.w, _587, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_369.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _396) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _534 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _534 = -_534;\n    }\n    float3 _442 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _534, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _442, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _534, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _442, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _457 = fast::normalize(param_2.normal);\n    float3 _472 = fast::normalize(float3(dot(in.fa_pre_r0, _457), dot(in.fa_pre_r1, _457), dot(in.fa_pre_r2, _457)));\n    float _484 = _472.z;\n    float2 e = _472.xy / float2((abs(_472.x) + abs(_472.y)) + abs(_484));\n    if (_484 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_187",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_398",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _53 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _68;\n    if (!_53)\n    {\n        _68 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_inst_base& _190 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _190.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    out.gl_Position = _173.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_173",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
            "msl_buffer_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _222)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_222.fa_joint_rows[_213] * weights[i]);\n        r1 += (_222.fa_joint_rows[_213 + 1] * weights[i]);\n        r2 += (_222.fa_joint_rows[_213 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _178)\n{\n    float3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * _178.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    bool _58 = fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5;\n    bool _73;\n    if (!_58)\n    {\n        _73 = ((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _178 [[buffer(0)]], constant fa_skin& _222 [[buffer(3)]], constant fa_inst_base& _302 [[buffer(6)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = _302.fa_base_model * fa_skin_matrix(param, param_1, _222);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _178);\n    vertex0(param_8, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    out.gl_Position = _178.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_178",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_222",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_302",
            "msl_buffer_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          }
        ]
      }
    }
  }
}
