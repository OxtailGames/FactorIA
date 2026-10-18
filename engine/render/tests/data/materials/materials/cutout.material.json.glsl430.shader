{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_shadow_pos;\nlayout(location = 4) in vec4 fa_inst_m0;\nlayout(location = 5) in vec4 fa_inst_m1;\nlayout(location = 6) in vec4 fa_inst_m2;\nlayout(location = 7) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    VertexData _151 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vec3 _260 = _151.world_pos;\n    vec4 _158 = vec4(_260, 1.0);\n    fa_world_pos = _260;\n    fa_world_normal = _151.world_normal;\n    fa_world_tangent = _151.world_tangent;\n    fa_uv = _151.uv;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _158;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _158;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_material[1];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 4) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _145 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _152 = _145 * fa_mesh_fs_params[2];\n    vec3 _964 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _184 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _189 = _184.xy * fa_mesh_fs_params[6].x;\n        vec3 _981 = _184;\n        _981.x = _189.x;\n        _981.y = _189.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _981;\n        _964 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _207 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_152.xyz, _152.w, _964, clamp(fa_mesh_fs_params[5].x * _207.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _207.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _274 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _274;\n    vec2 suv = (_274.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _986 = p;\n        _986.z = (_986.z * 0.5) + 0.5;\n        p = _986;\n    }\n    else\n    {\n        vec2 _989 = suv;\n        _989.y = 1.0 - _989.y;\n        suv = _989;\n    }\n    bool _301 = suv.x < 0.0;\n    bool _308;\n    if (!_301)\n    {\n        _308 = suv.x > 1.0;\n    }\n    else\n    {\n        _308 = _301;\n    }\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.y < 0.0;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y > 1.0;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = p.z > 1.0;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    if (_329)\n    {\n        return 1.0;\n    }\n    float _343 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _343) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _484 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _487 = _484.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_487 * _487, exp2((-9.27999973297119140625) * ndv)) * _487) + _484.y)) + _484.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _404 = rough * rough;\n    float _437 = 0.60000002384185791015625 * _404;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _404)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _437, 0.0500000007450580596923828125 + _437, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_404 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _914 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _914 = -_914;\n    }\n    vec3 _544 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _545 = normalize(_544);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing);\n    Surface _550 = fa_standard_surface(param);\n    vec3 _933 = _550.albedo;\n    float _934 = _550.alpha;\n    vec3 _935 = _550.normal;\n    float _936 = _550.metallic;\n    float _937 = _550.roughness;\n    float _938 = _550.occlusion;\n    vec3 _939 = _550.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing);\n    Surface param_2 = _550;\n    surface(param_1, param_2);\n    _933 = param_2.albedo;\n    _934 = param_2.alpha;\n    _935 = param_2.normal;\n    _936 = param_2.metallic;\n    _937 = param_2.roughness;\n    _938 = param_2.occlusion;\n    _939 = param_2.emission;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _933;\n    }\n    else\n    {\n        vec3 _583 = normalize(_935);\n        float _590 = clamp(_936, 0.0, 1.0);\n        float _594 = clamp(_937, 0.0500000007450580596923828125, 1.0);\n        float _598 = _594 * _594;\n        float _602 = _598 * _598;\n        float _608 = max(dot(_583, _545), 9.9999997473787516355514526367188e-05);\n        vec3 _614 = _933 * (1.0 - _590);\n        vec3 _622 = mix(vec3(0.039999999105930328369140625), _933, vec3(_590));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _614) * _938;\n        int _635 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _635)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _664 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_664)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _681 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _684 = length(_681);\n                l = _681 / vec3(max(_684, 9.9999997473787516355514526367188e-05));\n                float _699 = _684 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _705 = clamp(1.0 - (_699 * _699), 0.0, 1.0);\n                atten = _705 * _705;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _739 = max(dot(_583, l), 0.0);\n            if (_664 && (li == 0))\n            {\n                vec3 param_3 = _914;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _758 = normalize(l + _545);\n            float _763 = max(dot(_583, _758), 0.0);\n            float _776 = ((_763 * _763) * (_602 - 1.0)) + 1.0;\n            lit += (((_614 + (((_622 + ((vec3(1.0) - _622) * pow(1.0 - max(dot(_545, _758), 0.0), 5.0))) * (((_602 / ((3.1415927410125732421875 * _776) * _776)) * (0.5 / max(mix((2.0 * _739) * _608, _739 + _608, _598), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _739))) * fa_lights[li * 1 + 32].xyz) * (_739 * atten));\n        }\n        float param_5 = _594;\n        float param_6 = _608;\n        vec2 _844 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_545, _583);\n        float param_8 = _594;\n        vec3 _862 = lit;\n        vec3 _863 = _862 + ((fa_environment(param_7, param_8) * ((_622 * _844.x) + vec3(_844.y))) * _938);\n        lit = _863;\n        result = _863;\n    }\n    result += _939;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _887 = fa_mesh_fs_params[7].w * length(_544);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_887) * _887), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _934);\n}\n\n",
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
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 7,
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
            "inst_name": "_127",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_561",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_658",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering"
          },
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          },
          {
            "slot": 6,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_shadow_pos;\nlayout(location = 4) in vec4 fa_inst_m0;\nlayout(location = 5) in vec4 fa_inst_m1;\nlayout(location = 6) in vec4 fa_inst_m2;\nlayout(location = 7) in vec4 fa_inst_m3;\nlayout(location = 8) in vec4 fa_joints;\nlayout(location = 9) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _167 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_167 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_167 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_167 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _70 = cross(model[1].xyz, model[2].xyz);\n    float _76 = (dot(model[0].xyz, _70) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_70 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _76, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _76), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    VertexData _264 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vec3 _381 = _264.world_pos;\n    vec4 _271 = vec4(_381, 1.0);\n    fa_world_pos = _381;\n    fa_world_normal = _264.world_normal;\n    fa_world_tangent = _264.world_tangent;\n    fa_uv = _264.uv;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _271;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _271;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_material[1];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 4) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _145 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _152 = _145 * fa_mesh_fs_params[2];\n    vec3 _964 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _184 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _189 = _184.xy * fa_mesh_fs_params[6].x;\n        vec3 _981 = _184;\n        _981.x = _189.x;\n        _981.y = _189.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _981;\n        _964 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _207 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_152.xyz, _152.w, _964, clamp(fa_mesh_fs_params[5].x * _207.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _207.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _274 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _274;\n    vec2 suv = (_274.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _986 = p;\n        _986.z = (_986.z * 0.5) + 0.5;\n        p = _986;\n    }\n    else\n    {\n        vec2 _989 = suv;\n        _989.y = 1.0 - _989.y;\n        suv = _989;\n    }\n    bool _301 = suv.x < 0.0;\n    bool _308;\n    if (!_301)\n    {\n        _308 = suv.x > 1.0;\n    }\n    else\n    {\n        _308 = _301;\n    }\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.y < 0.0;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y > 1.0;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = p.z > 1.0;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    if (_329)\n    {\n        return 1.0;\n    }\n    float _343 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _343) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _484 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _487 = _484.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_487 * _487, exp2((-9.27999973297119140625) * ndv)) * _487) + _484.y)) + _484.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _404 = rough * rough;\n    float _437 = 0.60000002384185791015625 * _404;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _404)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _437, 0.0500000007450580596923828125 + _437, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_404 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _914 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _914 = -_914;\n    }\n    vec3 _544 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _545 = normalize(_544);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing);\n    Surface _550 = fa_standard_surface(param);\n    vec3 _933 = _550.albedo;\n    float _934 = _550.alpha;\n    vec3 _935 = _550.normal;\n    float _936 = _550.metallic;\n    float _937 = _550.roughness;\n    float _938 = _550.occlusion;\n    vec3 _939 = _550.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing);\n    Surface param_2 = _550;\n    surface(param_1, param_2);\n    _933 = param_2.albedo;\n    _934 = param_2.alpha;\n    _935 = param_2.normal;\n    _936 = param_2.metallic;\n    _937 = param_2.roughness;\n    _938 = param_2.occlusion;\n    _939 = param_2.emission;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _933;\n    }\n    else\n    {\n        vec3 _583 = normalize(_935);\n        float _590 = clamp(_936, 0.0, 1.0);\n        float _594 = clamp(_937, 0.0500000007450580596923828125, 1.0);\n        float _598 = _594 * _594;\n        float _602 = _598 * _598;\n        float _608 = max(dot(_583, _545), 9.9999997473787516355514526367188e-05);\n        vec3 _614 = _933 * (1.0 - _590);\n        vec3 _622 = mix(vec3(0.039999999105930328369140625), _933, vec3(_590));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _614) * _938;\n        int _635 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _635)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _664 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_664)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _681 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _684 = length(_681);\n                l = _681 / vec3(max(_684, 9.9999997473787516355514526367188e-05));\n                float _699 = _684 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _705 = clamp(1.0 - (_699 * _699), 0.0, 1.0);\n                atten = _705 * _705;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _739 = max(dot(_583, l), 0.0);\n            if (_664 && (li == 0))\n            {\n                vec3 param_3 = _914;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _758 = normalize(l + _545);\n            float _763 = max(dot(_583, _758), 0.0);\n            float _776 = ((_763 * _763) * (_602 - 1.0)) + 1.0;\n            lit += (((_614 + (((_622 + ((vec3(1.0) - _622) * pow(1.0 - max(dot(_545, _758), 0.0), 5.0))) * (((_602 / ((3.1415927410125732421875 * _776) * _776)) * (0.5 / max(mix((2.0 * _739) * _608, _739 + _608, _598), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _739))) * fa_lights[li * 1 + 32].xyz) * (_739 * atten));\n        }\n        float param_5 = _594;\n        float param_6 = _608;\n        vec2 _844 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_545, _583);\n        float param_8 = _594;\n        vec3 _862 = lit;\n        vec3 _863 = _862 + ((fa_environment(param_7, param_8) * ((_622 * _844.x) + vec3(_844.y))) * _938);\n        lit = _863;\n        result = _863;\n    }\n    result += _939;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _887 = fa_mesh_fs_params[7].w * length(_544);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_887) * _887), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _934);\n}\n\n",
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
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 9,
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
            "inst_name": "_132",
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
            "inst_name": "_176",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_561",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_658",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering"
          },
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          },
          {
            "slot": 6,
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _57 = cross(model[1].xyz, model[2].xyz);\n    float _63 = (dot(model[0].xyz, _57) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_57 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _63, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _63), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    VertexData _180 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vec3 _225 = _180.world_pos;\n    fa_world_pos = _225;\n    fa_world_normal = _180.world_normal;\n    fa_world_tangent = _180.world_tangent;\n    fa_uv = _180.uv;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_225, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    vec3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    vec3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    vec3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _130 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _137 = _130 * fa_mesh_fs_params[2];\n    vec3 _362 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _169 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _174 = _169.xy * fa_mesh_fs_params[6].x;\n        vec3 _377 = _169;\n        _377.x = _174.x;\n        _377.y = _174.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _377;\n        _362 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _192 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_137.xyz, _137.w, _362, clamp(fa_mesh_fs_params[5].x * _192.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _192.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    vec3 _312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _312 = -_312;\n    }\n    vec3 _279 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_119",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_295",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering"
          },
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _159 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_159 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_159 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_159 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _62 = cross(model[1].xyz, model[2].xyz);\n    float _68 = (dot(model[0].xyz, _62) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_62 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _68, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _68), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    VertexData _301 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6);\n    vec3 _346 = _301.world_pos;\n    fa_world_pos = _346;\n    fa_world_normal = _301.world_normal;\n    fa_world_tangent = _301.world_tangent;\n    fa_uv = _301.uv;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_346, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    vec3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    vec3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    vec3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _130 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _137 = _130 * fa_mesh_fs_params[2];\n    vec3 _362 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _169 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _174 = _169.xy * fa_mesh_fs_params[6].x;\n        vec3 _377 = _169;\n        _377.x = _174.x;\n        _377.y = _174.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _377;\n        _362 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _192 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_137.xyz, _137.w, _362, clamp(fa_mesh_fs_params[5].x * _192.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _192.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    vec3 _312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _312 = -_312;\n    }\n    vec3 _279 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_124",
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
            "inst_name": "_168",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_295",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering"
          },
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    }
  }
}
