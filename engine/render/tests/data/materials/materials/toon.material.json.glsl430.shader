{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "5dd0da916b10a9a6f999383491342fc1c21819329ed9afcc0f9d0e7d6522a261",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _158.world_pos;\n    vec4 _165 = vec4(_270, 1.0);\n    fa_world_pos = _270;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _165;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _165;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _215 = fa_linear_to_srgb(param);\n        c = _215;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _223 = fa_srgb_to_linear(param_1);\n            c = _223;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _67;\n    if (i.front_facing)\n    {\n        _67 = i.world_normal;\n    }\n    else\n    {\n        _67 = -i.world_normal;\n    }\n    vec3 _92 = normalize(i.world_tangent.xyz - (_67 * dot(_67, i.world_tangent.xyz)));\n    vec3 _120 = normalize(((_92 * m.x) + ((cross(_67, _92) * i.world_tangent.w) * m.y)) + (_67 * m.z));\n    vec3 _123;\n    if (i.front_facing)\n    {\n        _123 = _120;\n    }\n    else\n    {\n        _123 = -_120;\n    }\n    return _123;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _265 = fa_tex_fix(param_2, param_3);\n    vec4 _1152 = base_t;\n    _1152.x = _265.x;\n    _1152.y = _265.y;\n    _1152.z = _265.z;\n    base_t = _1152;\n    vec4 _281 = (_1152 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _1138 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _314 = fa_tex_fix(param_6, param_7);\n        vec3 _318 = (_314 * 2.0) - vec3(1.0);\n        vec2 _323 = _318.xy * fa_mesh_fs_params[6].x;\n        vec3 _1160 = _318;\n        _1160.x = _323.x;\n        _1160.y = _323.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _1160;\n        _1138 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _352 = fa_tex_fix(param_12, param_13);\n    vec4 _1163 = mrt;\n    _1163.x = _352.x;\n    _1163.y = _352.y;\n    _1163.z = _352.z;\n    mrt = _1163;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _420 = fa_tex_fix(param_20, param_21);\n    return Surface(_281.xyz, _281.w, _1138, clamp(fa_mesh_fs_params[5].x * _352.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _352.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _420));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _442 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _442;\n    vec2 suv = (_442.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _1171 = p;\n        _1171.z = (_1171.z * 0.5) + 0.5;\n        p = _1171;\n    }\n    else\n    {\n        vec2 _1174 = suv;\n        _1174.y = 1.0 - _1174.y;\n        suv = _1174;\n    }\n    bool _469 = suv.x < 0.0;\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.x > 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = suv.y < 0.0;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    bool _490;\n    if (!_483)\n    {\n        _490 = suv.y > 1.0;\n    }\n    else\n    {\n        _490 = _483;\n    }\n    bool _497;\n    if (!_490)\n    {\n        _497 = p.z > 1.0;\n    }\n    else\n    {\n        _497 = _490;\n    }\n    if (_497)\n    {\n        return 1.0;\n    }\n    float _511 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _511) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _144;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _144 = 1.0;\n    }\n    else\n    {\n        _144 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _144;\n}\n\nvoid main()\n{\n    vec3 _1055 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1055 = -_1055;\n    }\n    vec3 _606 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n    Surface _611 = fa_standard_surface(param);\n    vec3 _1086 = _611.albedo;\n    float _1087 = _611.alpha;\n    vec3 _1088 = _611.normal;\n    float _1089 = _611.metallic;\n    float _1090 = _611.roughness;\n    float _1091 = _611.occlusion;\n    vec3 _1092 = _611.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n    Surface param_2 = _611;\n    surface(param_1, param_2);\n    _1086 = param_2.albedo;\n    _1087 = param_2.alpha;\n    _1088 = param_2.normal;\n    _1089 = param_2.metallic;\n    _1090 = param_2.roughness;\n    _1091 = param_2.occlusion;\n    _1092 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1086;\n    }\n    else\n    {\n        _1088 = normalize(_1088);\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _1086) * _1091;\n        int _652 = int(fa_mesh_fs_params[10].x);\n        vec3 l;\n        int _785;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _652)\n            {\n                break;\n            }\n            float atten = 1.0;\n            float dist = 0.0;\n            bool _682 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_682)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _699 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _701 = length(_699);\n                dist = _701;\n                l = _699 / vec3(max(_701, 9.9999997473787516355514526367188e-05));\n                float _717 = _701 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _723 = clamp(1.0 - (_717 * _717), 0.0, 1.0);\n                atten = _723 * _723;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_682 && (li == 0))\n            {\n                vec3 param_3 = _1055;\n                vec3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            if (_682)\n            {\n                _785 = 0;\n            }\n            else\n            {\n                _785 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n            }\n            SurfaceInput param_5 = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n            Surface param_6 = Surface(_1086, _1087, _1088, _1089, _1090, _1091, _1092);\n            LightSample param_7 = LightSample(l, fa_lights[li * 1 + 32].xyz * (atten * shadow), atten, shadow, dist, _785);\n            lit += light(param_5, param_6, param_7);\n        }\n        result = lit;\n    }\n    result += _1092;\n    bool _813 = fa_mesh_fs_params[7].w > 0.0;\n    bool _821;\n    if (!_813)\n    {\n        _821 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _821 = _813;\n    }\n    if (_821)\n    {\n        vec3 _830 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _837 = dot(_830, fa_mesh_fs_params[9].xyz);\n        bool _841 = fa_mesh_fs_params[9].w > 0.5;\n        float _842;\n        if (_841)\n        {\n            _842 = _837;\n        }\n        else\n        {\n            _842 = length(_830);\n        }\n        float _854 = _842 - fa_mesh_fs_params[8].x;\n        if (_854 > 0.0)\n        {\n            float _863 = fa_mesh_fs_params[7].w * _854;\n            float tau = _863 * _863;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _879;\n                if (_841)\n                {\n                    _879 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _837);\n                }\n                else\n                {\n                    _879 = fa_mesh_fs_params[0].y;\n                }\n                float _900 = mix(_879, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _842, 0.0, 1.0));\n                float _904 = fa_world_pos.y - _900;\n                float _909 = _900 - fa_mesh_fs_params[8].z;\n                float _914 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _917 = _909 <= 0.0;\n                bool _918 = !_917;\n                bool _924;\n                if (_918)\n                {\n                    _924 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _924 = _917;\n                }\n                float _925;\n                if (_924)\n                {\n                    _925 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _925 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _909, 80.0));\n                }\n                bool _952;\n                if (_918)\n                {\n                    _952 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _952 = _917;\n                }\n                float _953;\n                if (_952)\n                {\n                    _953 = fa_mesh_fs_params[8].y * _909;\n                }\n                else\n                {\n                    _953 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _909, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _978 = _914 <= 0.0;\n                bool _985;\n                if (!_978)\n                {\n                    _985 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _985 = _978;\n                }\n                float _986;\n                if (_985)\n                {\n                    _986 = fa_mesh_fs_params[8].y * _914;\n                }\n                else\n                {\n                    _986 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _914, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1013;\n                if (abs(_904) < 0.001000000047497451305389404296875)\n                {\n                    _1013 = _925;\n                }\n                else\n                {\n                    _1013 = (_986 - _953) / _904;\n                }\n                tau += (_854 * max(_1013, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _1087);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_151",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_675",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_172 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_172 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_172 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _271.world_pos;\n    vec4 _278 = vec4(_391, 1.0);\n    fa_world_pos = _391;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _278;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _278;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _215 = fa_linear_to_srgb(param);\n        c = _215;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _223 = fa_srgb_to_linear(param_1);\n            c = _223;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _67;\n    if (i.front_facing)\n    {\n        _67 = i.world_normal;\n    }\n    else\n    {\n        _67 = -i.world_normal;\n    }\n    vec3 _92 = normalize(i.world_tangent.xyz - (_67 * dot(_67, i.world_tangent.xyz)));\n    vec3 _120 = normalize(((_92 * m.x) + ((cross(_67, _92) * i.world_tangent.w) * m.y)) + (_67 * m.z));\n    vec3 _123;\n    if (i.front_facing)\n    {\n        _123 = _120;\n    }\n    else\n    {\n        _123 = -_120;\n    }\n    return _123;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _265 = fa_tex_fix(param_2, param_3);\n    vec4 _1152 = base_t;\n    _1152.x = _265.x;\n    _1152.y = _265.y;\n    _1152.z = _265.z;\n    base_t = _1152;\n    vec4 _281 = (_1152 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _1138 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _314 = fa_tex_fix(param_6, param_7);\n        vec3 _318 = (_314 * 2.0) - vec3(1.0);\n        vec2 _323 = _318.xy * fa_mesh_fs_params[6].x;\n        vec3 _1160 = _318;\n        _1160.x = _323.x;\n        _1160.y = _323.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _1160;\n        _1138 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _352 = fa_tex_fix(param_12, param_13);\n    vec4 _1163 = mrt;\n    _1163.x = _352.x;\n    _1163.y = _352.y;\n    _1163.z = _352.z;\n    mrt = _1163;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _420 = fa_tex_fix(param_20, param_21);\n    return Surface(_281.xyz, _281.w, _1138, clamp(fa_mesh_fs_params[5].x * _352.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _352.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _420));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _442 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _442;\n    vec2 suv = (_442.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _1171 = p;\n        _1171.z = (_1171.z * 0.5) + 0.5;\n        p = _1171;\n    }\n    else\n    {\n        vec2 _1174 = suv;\n        _1174.y = 1.0 - _1174.y;\n        suv = _1174;\n    }\n    bool _469 = suv.x < 0.0;\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.x > 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = suv.y < 0.0;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    bool _490;\n    if (!_483)\n    {\n        _490 = suv.y > 1.0;\n    }\n    else\n    {\n        _490 = _483;\n    }\n    bool _497;\n    if (!_490)\n    {\n        _497 = p.z > 1.0;\n    }\n    else\n    {\n        _497 = _490;\n    }\n    if (_497)\n    {\n        return 1.0;\n    }\n    float _511 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _511) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _144;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _144 = 1.0;\n    }\n    else\n    {\n        _144 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _144;\n}\n\nvoid main()\n{\n    vec3 _1055 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1055 = -_1055;\n    }\n    vec3 _606 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n    Surface _611 = fa_standard_surface(param);\n    vec3 _1086 = _611.albedo;\n    float _1087 = _611.alpha;\n    vec3 _1088 = _611.normal;\n    float _1089 = _611.metallic;\n    float _1090 = _611.roughness;\n    float _1091 = _611.occlusion;\n    vec3 _1092 = _611.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n    Surface param_2 = _611;\n    surface(param_1, param_2);\n    _1086 = param_2.albedo;\n    _1087 = param_2.alpha;\n    _1088 = param_2.normal;\n    _1089 = param_2.metallic;\n    _1090 = param_2.roughness;\n    _1091 = param_2.occlusion;\n    _1092 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1086;\n    }\n    else\n    {\n        _1088 = normalize(_1088);\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _1086) * _1091;\n        int _652 = int(fa_mesh_fs_params[10].x);\n        vec3 l;\n        int _785;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _652)\n            {\n                break;\n            }\n            float atten = 1.0;\n            float dist = 0.0;\n            bool _682 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_682)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _699 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _701 = length(_699);\n                dist = _701;\n                l = _699 / vec3(max(_701, 9.9999997473787516355514526367188e-05));\n                float _717 = _701 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _723 = clamp(1.0 - (_717 * _717), 0.0, 1.0);\n                atten = _723 * _723;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_682 && (li == 0))\n            {\n                vec3 param_3 = _1055;\n                vec3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            if (_682)\n            {\n                _785 = 0;\n            }\n            else\n            {\n                _785 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n            }\n            SurfaceInput param_5 = SurfaceInput(fa_world_pos, _1055, fa_world_tangent, fa_uv, fa_vertex_color, _606, gl_FrontFacing);\n            Surface param_6 = Surface(_1086, _1087, _1088, _1089, _1090, _1091, _1092);\n            LightSample param_7 = LightSample(l, fa_lights[li * 1 + 32].xyz * (atten * shadow), atten, shadow, dist, _785);\n            lit += light(param_5, param_6, param_7);\n        }\n        result = lit;\n    }\n    result += _1092;\n    bool _813 = fa_mesh_fs_params[7].w > 0.0;\n    bool _821;\n    if (!_813)\n    {\n        _821 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _821 = _813;\n    }\n    if (_821)\n    {\n        vec3 _830 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _837 = dot(_830, fa_mesh_fs_params[9].xyz);\n        bool _841 = fa_mesh_fs_params[9].w > 0.5;\n        float _842;\n        if (_841)\n        {\n            _842 = _837;\n        }\n        else\n        {\n            _842 = length(_830);\n        }\n        float _854 = _842 - fa_mesh_fs_params[8].x;\n        if (_854 > 0.0)\n        {\n            float _863 = fa_mesh_fs_params[7].w * _854;\n            float tau = _863 * _863;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _879;\n                if (_841)\n                {\n                    _879 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _837);\n                }\n                else\n                {\n                    _879 = fa_mesh_fs_params[0].y;\n                }\n                float _900 = mix(_879, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _842, 0.0, 1.0));\n                float _904 = fa_world_pos.y - _900;\n                float _909 = _900 - fa_mesh_fs_params[8].z;\n                float _914 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _917 = _909 <= 0.0;\n                bool _918 = !_917;\n                bool _924;\n                if (_918)\n                {\n                    _924 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _924 = _917;\n                }\n                float _925;\n                if (_924)\n                {\n                    _925 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _925 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _909, 80.0));\n                }\n                bool _952;\n                if (_918)\n                {\n                    _952 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _952 = _917;\n                }\n                float _953;\n                if (_952)\n                {\n                    _953 = fa_mesh_fs_params[8].y * _909;\n                }\n                else\n                {\n                    _953 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _909, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _978 = _914 <= 0.0;\n                bool _985;\n                if (!_978)\n                {\n                    _985 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _985 = _978;\n                }\n                float _986;\n                if (_985)\n                {\n                    _986 = fa_mesh_fs_params[8].y * _914;\n                }\n                else\n                {\n                    _986 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _914, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1013;\n                if (abs(_904) < 0.001000000047497451305389404296875)\n                {\n                    _1013 = _925;\n                }\n                else\n                {\n                    _1013 = (_986 - _953) / _904;\n                }\n                tau += (_854 * max(_1013, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _1087);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_151",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_675",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _158.world_pos;\n    mat4 _162 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _169 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_pre_depth = -(_162 * _169).z;\n    fa_pre_r0 = vec3(_162[0].x, _162[1].x, _162[2].x);\n    fa_pre_r1 = vec3(_162[0].y, _162[1].y, _162[2].y);\n    fa_pre_r2 = vec3(_162[0].z, _162[1].z, _162[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _169;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    vec3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    vec3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    vec3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _223 = fa_tex_fix(param_2, param_3);\n    vec4 _581 = base_t;\n    _581.x = _223.x;\n    _581.y = _223.y;\n    _581.z = _223.z;\n    base_t = _581;\n    vec4 _239 = (_581 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _562 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _273 = fa_tex_fix(param_6, param_7);\n        vec3 _277 = (_273 * 2.0) - vec3(1.0);\n        vec2 _282 = _277.xy * fa_mesh_fs_params[6].x;\n        vec3 _589 = _277;\n        _589.x = _282.x;\n        _589.y = _282.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _589;\n        _562 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _311 = fa_tex_fix(param_12, param_13);\n    vec4 _592 = mrt;\n    _592.x = _311.x;\n    _592.y = _311.y;\n    _592.z = _311.z;\n    mrt = _592;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _379 = fa_tex_fix(param_20, param_21);\n    return Surface(_239.xyz, _239.w, _562, clamp(fa_mesh_fs_params[5].x * _311.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _311.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_352.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _379));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    vec3 _509 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _509 = -_509;\n    }\n    vec3 _424 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _509, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _509, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _439 = normalize(param_2.normal);\n    vec3 _454 = normalize(vec3(dot(fa_pre_r0, _439), dot(fa_pre_r1, _439), dot(fa_pre_r2, _439)));\n    float _466 = _454.z;\n    vec2 e = _454.xy / vec2((abs(_454.x) + abs(_454.y)) + abs(_466));\n    if (_466 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_172 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_172 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_172 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _271.world_pos;\n    mat4 _275 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _282 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_pre_depth = -(_275 * _282).z;\n    fa_pre_r0 = vec3(_275[0].x, _275[1].x, _275[2].x);\n    fa_pre_r1 = vec3(_275[0].y, _275[1].y, _275[2].y);\n    fa_pre_r2 = vec3(_275[0].z, _275[1].z, _275[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _282;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    vec3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    vec3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    vec3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _223 = fa_tex_fix(param_2, param_3);\n    vec4 _581 = base_t;\n    _581.x = _223.x;\n    _581.y = _223.y;\n    _581.z = _223.z;\n    base_t = _581;\n    vec4 _239 = (_581 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _562 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _273 = fa_tex_fix(param_6, param_7);\n        vec3 _277 = (_273 * 2.0) - vec3(1.0);\n        vec2 _282 = _277.xy * fa_mesh_fs_params[6].x;\n        vec3 _589 = _277;\n        _589.x = _282.x;\n        _589.y = _282.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _589;\n        _562 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _311 = fa_tex_fix(param_12, param_13);\n    vec4 _592 = mrt;\n    _592.x = _311.x;\n    _592.y = _311.y;\n    _592.z = _311.z;\n    mrt = _592;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _379 = fa_tex_fix(param_20, param_21);\n    return Surface(_239.xyz, _239.w, _562, clamp(fa_mesh_fs_params[5].x * _311.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _311.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_352.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _379));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    vec3 _509 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _509 = -_509;\n    }\n    vec3 _424 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _509, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _509, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _439 = normalize(param_2.normal);\n    vec3 _454 = normalize(vec3(dot(fa_pre_r0, _439), dot(fa_pre_r1, _439), dot(fa_pre_r2, _439)));\n    float _466 = _454.z;\n    vec2 e = _454.xy / vec2((abs(_454.x) + abs(_454.y)) + abs(_466));\n    if (_466 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
