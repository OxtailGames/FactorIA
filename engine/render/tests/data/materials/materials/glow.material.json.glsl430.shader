{
  "format": "factoria.shader/1",
  "engine": "0.30.1",
  "template": "b5ef3e931c5673e3120cb224375a6b96104a5da86f18b53f68e85e69e4b04423",
  "slang": "glsl430",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _158.world_pos;\n    vec4 _165 = vec4(_270, 1.0);\n    fa_world_pos = _270;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _165;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _165;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(vec3 c, float mode)\n{\n    vec3 _196;\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _201 = fa_linear_to_srgb(param);\n        _196 = _201;\n    }\n    else\n    {\n        vec3 _206;\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _211 = fa_srgb_to_linear(param_1);\n            _206 = _211;\n        }\n        else\n        {\n            _206 = c;\n        }\n        _196 = _206;\n    }\n    return _196;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    vec3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    vec3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    vec3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _257 = fa_tex_fix(param_2, param_3);\n    vec4 _1132 = base_t;\n    _1132.x = _257.x;\n    _1132.y = _257.y;\n    _1132.z = _257.z;\n    base_t = _1132;\n    vec4 _272 = (_1132 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _1117 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _309 = (fa_tex_fix(param_6, param_7) * 2.0) - vec3(1.0);\n        vec2 _314 = _309.xy * fa_mesh_fs_params[6].x;\n        vec3 _1140 = _309;\n        _1140.x = _314.x;\n        _1140.y = _314.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _1140;\n        _1117 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _343 = fa_tex_fix(param_12, param_13);\n    vec4 _1143 = mrt;\n    _1143.x = _343.x;\n    float _347 = _343.y;\n    _1143.y = _347;\n    float _349 = _343.z;\n    _1143.z = _349;\n    mrt = _1143;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    return Surface(_272.xyz, _272.w, _1117, clamp(fa_mesh_fs_params[5].x * _349, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _347, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (fa_tex_fix(param_16, param_17).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * fa_tex_fix(param_20, param_21)));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _433 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _433;\n    vec2 suv = (_433.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _1151 = p;\n        _1151.z = (_1151.z * 0.5) + 0.5;\n        p = _1151;\n    }\n    else\n    {\n        vec2 _1154 = suv;\n        _1154.y = 1.0 - _1154.y;\n        suv = _1154;\n    }\n    bool _460 = suv.x < 0.0;\n    bool _467;\n    if (!_460)\n    {\n        _467 = suv.x > 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = suv.y < 0.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    bool _481;\n    if (!_474)\n    {\n        _481 = suv.y > 1.0;\n    }\n    else\n    {\n        _481 = _474;\n    }\n    bool _488;\n    if (!_481)\n    {\n        _488 = p.z > 1.0;\n    }\n    else\n    {\n        _488 = _481;\n    }\n    if (_488)\n    {\n        return 1.0;\n    }\n    float _502 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _502) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _643 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _646 = _643.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_646 * _646, exp2((-9.27999973297119140625) * ndv)) * _646) + _643.y)) + _643.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _563 = rough * rough;\n    float _596 = 0.60000002384185791015625 * _563;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _563)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _596, 0.0500000007450580596923828125 + _596, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_563 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _1064 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1064 = -_1064;\n    }\n    vec3 _706 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _707 = normalize(_706);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1064, fa_world_tangent, fa_uv, fa_vertex_color, _707, gl_FrontFacing);\n    Surface _712 = fa_standard_surface(param);\n    vec3 _1086 = _712.albedo;\n    float _1087 = _712.alpha;\n    vec3 _1088 = _712.normal;\n    float _1089 = _712.metallic;\n    float _1090 = _712.roughness;\n    float _1091 = _712.occlusion;\n    vec3 _1092 = _712.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1064, fa_world_tangent, fa_uv, fa_vertex_color, _707, gl_FrontFacing);\n    Surface param_2 = _712;\n    surface(param_1, param_2);\n    _1086 = param_2.albedo;\n    _1087 = param_2.alpha;\n    _1088 = param_2.normal;\n    _1089 = param_2.metallic;\n    _1090 = param_2.roughness;\n    _1091 = param_2.occlusion;\n    _1092 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1086;\n    }\n    else\n    {\n        vec3 _734 = normalize(_1088);\n        float _741 = clamp(_1089, 0.0, 1.0);\n        float _745 = clamp(_1090, 0.0500000007450580596923828125, 1.0);\n        float _749 = _745 * _745;\n        float _753 = _749 * _749;\n        float _759 = max(dot(_734, _707), 9.9999997473787516355514526367188e-05);\n        vec3 _765 = _1086 * (1.0 - _741);\n        vec3 _773 = mix(vec3(0.039999999105930328369140625), _1086, vec3(_741));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _765) * _1091;\n        int _786 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _786)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _815 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_815)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _832 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _835 = length(_832);\n                l = _832 / vec3(max(_835, 9.9999997473787516355514526367188e-05));\n                float _850 = _835 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _856 = clamp(1.0 - (_850 * _850), 0.0, 1.0);\n                atten = _856 * _856;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _889 = max(dot(_734, l), 0.0);\n            if (_815 && (li == 0))\n            {\n                vec3 param_3 = _1064;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _908 = normalize(l + _707);\n            float _913 = max(dot(_734, _908), 0.0);\n            float _926 = ((_913 * _913) * (_753 - 1.0)) + 1.0;\n            lit += (((_765 + (((_773 + ((vec3(1.0) - _773) * pow(1.0 - max(dot(_707, _908), 0.0), 5.0))) * (((_753 / ((3.1415927410125732421875 * _926) * _926)) * (0.5 / max(mix((2.0 * _889) * _759, _889 + _759, _749), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _889))) * fa_lights[li * 1 + 32].xyz) * (_889 * atten));\n        }\n        float param_5 = _745;\n        float param_6 = _759;\n        vec2 _994 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_707, _734);\n        float param_8 = _745;\n        vec3 _1012 = lit;\n        vec3 _1013 = _1012 + ((fa_environment(param_7, param_8) * ((_773 * _994.x) + vec3(_994.y))) * _1091);\n        lit = _1013;\n        result = _1013;\n    }\n    result += _1092;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _1037 = fa_mesh_fs_params[7].w * length(_706);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_1037) * _1037), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _1087);\n}\n\n",
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
            "inst_name": "_136",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_246",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 12,
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
            "inst_name": "_809",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(vec3 c, float mode)\n{\n    vec3 _196;\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _201 = fa_linear_to_srgb(param);\n        _196 = _201;\n    }\n    else\n    {\n        vec3 _206;\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _211 = fa_srgb_to_linear(param_1);\n            _206 = _211;\n        }\n        else\n        {\n            _206 = c;\n        }\n        _196 = _206;\n    }\n    return _196;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    vec3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    vec3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    vec3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _257 = fa_tex_fix(param_2, param_3);\n    vec4 _1132 = base_t;\n    _1132.x = _257.x;\n    _1132.y = _257.y;\n    _1132.z = _257.z;\n    base_t = _1132;\n    vec4 _272 = (_1132 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _1117 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _309 = (fa_tex_fix(param_6, param_7) * 2.0) - vec3(1.0);\n        vec2 _314 = _309.xy * fa_mesh_fs_params[6].x;\n        vec3 _1140 = _309;\n        _1140.x = _314.x;\n        _1140.y = _314.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _1140;\n        _1117 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _343 = fa_tex_fix(param_12, param_13);\n    vec4 _1143 = mrt;\n    _1143.x = _343.x;\n    float _347 = _343.y;\n    _1143.y = _347;\n    float _349 = _343.z;\n    _1143.z = _349;\n    mrt = _1143;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    return Surface(_272.xyz, _272.w, _1117, clamp(fa_mesh_fs_params[5].x * _349, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _347, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (fa_tex_fix(param_16, param_17).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * fa_tex_fix(param_20, param_21)));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _433 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _433;\n    vec2 suv = (_433.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _1151 = p;\n        _1151.z = (_1151.z * 0.5) + 0.5;\n        p = _1151;\n    }\n    else\n    {\n        vec2 _1154 = suv;\n        _1154.y = 1.0 - _1154.y;\n        suv = _1154;\n    }\n    bool _460 = suv.x < 0.0;\n    bool _467;\n    if (!_460)\n    {\n        _467 = suv.x > 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = suv.y < 0.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    bool _481;\n    if (!_474)\n    {\n        _481 = suv.y > 1.0;\n    }\n    else\n    {\n        _481 = _474;\n    }\n    bool _488;\n    if (!_481)\n    {\n        _488 = p.z > 1.0;\n    }\n    else\n    {\n        _488 = _481;\n    }\n    if (_488)\n    {\n        return 1.0;\n    }\n    float _502 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _502) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _643 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _646 = _643.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_646 * _646, exp2((-9.27999973297119140625) * ndv)) * _646) + _643.y)) + _643.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _563 = rough * rough;\n    float _596 = 0.60000002384185791015625 * _563;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _563)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _596, 0.0500000007450580596923828125 + _596, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_563 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _1064 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1064 = -_1064;\n    }\n    vec3 _706 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _707 = normalize(_706);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1064, fa_world_tangent, fa_uv, fa_vertex_color, _707, gl_FrontFacing);\n    Surface _712 = fa_standard_surface(param);\n    vec3 _1086 = _712.albedo;\n    float _1087 = _712.alpha;\n    vec3 _1088 = _712.normal;\n    float _1089 = _712.metallic;\n    float _1090 = _712.roughness;\n    float _1091 = _712.occlusion;\n    vec3 _1092 = _712.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1064, fa_world_tangent, fa_uv, fa_vertex_color, _707, gl_FrontFacing);\n    Surface param_2 = _712;\n    surface(param_1, param_2);\n    _1086 = param_2.albedo;\n    _1087 = param_2.alpha;\n    _1088 = param_2.normal;\n    _1089 = param_2.metallic;\n    _1090 = param_2.roughness;\n    _1091 = param_2.occlusion;\n    _1092 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1086;\n    }\n    else\n    {\n        vec3 _734 = normalize(_1088);\n        float _741 = clamp(_1089, 0.0, 1.0);\n        float _745 = clamp(_1090, 0.0500000007450580596923828125, 1.0);\n        float _749 = _745 * _745;\n        float _753 = _749 * _749;\n        float _759 = max(dot(_734, _707), 9.9999997473787516355514526367188e-05);\n        vec3 _765 = _1086 * (1.0 - _741);\n        vec3 _773 = mix(vec3(0.039999999105930328369140625), _1086, vec3(_741));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _765) * _1091;\n        int _786 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _786)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _815 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_815)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _832 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _835 = length(_832);\n                l = _832 / vec3(max(_835, 9.9999997473787516355514526367188e-05));\n                float _850 = _835 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _856 = clamp(1.0 - (_850 * _850), 0.0, 1.0);\n                atten = _856 * _856;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _889 = max(dot(_734, l), 0.0);\n            if (_815 && (li == 0))\n            {\n                vec3 param_3 = _1064;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _908 = normalize(l + _707);\n            float _913 = max(dot(_734, _908), 0.0);\n            float _926 = ((_913 * _913) * (_753 - 1.0)) + 1.0;\n            lit += (((_765 + (((_773 + ((vec3(1.0) - _773) * pow(1.0 - max(dot(_707, _908), 0.0), 5.0))) * (((_753 / ((3.1415927410125732421875 * _926) * _926)) * (0.5 / max(mix((2.0 * _889) * _759, _889 + _759, _749), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _889))) * fa_lights[li * 1 + 32].xyz) * (_889 * atten));\n        }\n        float param_5 = _745;\n        float param_6 = _759;\n        vec2 _994 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_707, _734);\n        float param_8 = _745;\n        vec3 _1012 = lit;\n        vec3 _1013 = _1012 + ((fa_environment(param_7, param_8) * ((_773 * _994.x) + vec3(_994.y))) * _1091);\n        lit = _1013;\n        result = _1013;\n    }\n    result += _1092;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _1037 = fa_mesh_fs_params[7].w * length(_706);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_1037) * _1037), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _1087);\n}\n\n",
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
            "inst_name": "_136",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_246",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 12,
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
            "inst_name": "_809",
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
    }
  }
}
