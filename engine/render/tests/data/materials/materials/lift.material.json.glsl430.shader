{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "glsl430",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_shadow_pos;\nlayout(location = 4) in vec4 fa_inst_m0;\nlayout(location = 5) in vec4 fa_inst_m1;\nlayout(location = 6) in vec4 fa_inst_m2;\nlayout(location = 7) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vertex(param_5);\n    vec4 _176 = vec4(param_5.world_pos, 1.0);\n    fa_world_pos = param_5.world_pos;\n    fa_world_normal = param_5.world_normal;\n    fa_world_tangent = param_5.world_tangent;\n    fa_uv = param_5.uv;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _176;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _176;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 4) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _133 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _140 = _133 * fa_mesh_fs_params[2];\n    vec3 _945 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _173 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _178 = _173.xy * fa_mesh_fs_params[6].x;\n        vec3 _962 = _173;\n        _962.x = _178.x;\n        _962.y = _178.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _962;\n        _945 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _196 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_140.xyz, _140.w, _945, clamp(fa_mesh_fs_params[5].x * _196.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _196.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _263 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _263;\n    vec2 suv = (_263.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _967 = p;\n        _967.z = (_967.z * 0.5) + 0.5;\n        p = _967;\n    }\n    else\n    {\n        vec2 _970 = suv;\n        _970.y = 1.0 - _970.y;\n        suv = _970;\n    }\n    bool _290 = suv.x < 0.0;\n    bool _297;\n    if (!_290)\n    {\n        _297 = suv.x > 1.0;\n    }\n    else\n    {\n        _297 = _290;\n    }\n    bool _304;\n    if (!_297)\n    {\n        _304 = suv.y < 0.0;\n    }\n    else\n    {\n        _304 = _297;\n    }\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.y > 1.0;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = p.z > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    if (_318)\n    {\n        return 1.0;\n    }\n    float _332 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _332) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _473 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _476 = _473.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_476 * _476, exp2((-9.27999973297119140625) * ndv)) * _476) + _473.y)) + _473.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _393 = rough * rough;\n    float _426 = 0.60000002384185791015625 * _393;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _393)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _426, 0.0500000007450580596923828125 + _426, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_393 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _895 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _895 = -_895;\n    }\n    vec3 _533 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _534 = normalize(_533);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _895, fa_world_tangent, fa_uv, _534, gl_FrontFacing);\n    Surface _539 = fa_standard_surface(param);\n    vec3 _914 = _539.albedo;\n    float _915 = _539.alpha;\n    vec3 _916 = _539.normal;\n    float _917 = _539.metallic;\n    float _918 = _539.roughness;\n    float _919 = _539.occlusion;\n    vec3 _920 = _539.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _895, fa_world_tangent, fa_uv, _534, gl_FrontFacing);\n    Surface param_2 = _539;\n    surface(param_1, param_2);\n    _914 = param_2.albedo;\n    _915 = param_2.alpha;\n    _916 = param_2.normal;\n    _917 = param_2.metallic;\n    _918 = param_2.roughness;\n    _919 = param_2.occlusion;\n    _920 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _914;\n    }\n    else\n    {\n        vec3 _561 = normalize(_916);\n        float _568 = clamp(_917, 0.0, 1.0);\n        float _572 = clamp(_918, 0.0500000007450580596923828125, 1.0);\n        float _576 = _572 * _572;\n        float _580 = _576 * _576;\n        float _586 = max(dot(_561, _534), 9.9999997473787516355514526367188e-05);\n        vec3 _592 = _914 * (1.0 - _568);\n        vec3 _600 = mix(vec3(0.039999999105930328369140625), _914, vec3(_568));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _592) * _919;\n        int _613 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _613)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _642 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_642)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _659 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _662 = length(_659);\n                l = _659 / vec3(max(_662, 9.9999997473787516355514526367188e-05));\n                float _677 = _662 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _683 = clamp(1.0 - (_677 * _677), 0.0, 1.0);\n                atten = _683 * _683;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _717 = max(dot(_561, l), 0.0);\n            if (_642 && (li == 0))\n            {\n                vec3 param_3 = _895;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _736 = normalize(l + _534);\n            float _741 = max(dot(_561, _736), 0.0);\n            float _754 = ((_741 * _741) * (_580 - 1.0)) + 1.0;\n            lit += (((_592 + (((_600 + ((vec3(1.0) - _600) * pow(1.0 - max(dot(_534, _736), 0.0), 5.0))) * (((_580 / ((3.1415927410125732421875 * _754) * _754)) * (0.5 / max(mix((2.0 * _717) * _586, _717 + _586, _576), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _717))) * fa_lights[li * 1 + 32].xyz) * (_717 * atten));\n        }\n        float param_5 = _572;\n        float param_6 = _586;\n        vec2 _822 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_534, _561);\n        float param_8 = _572;\n        vec3 _840 = lit;\n        vec3 _841 = _840 + ((fa_environment(param_7, param_8) * ((_600 * _822.x) + vec3(_822.y))) * _919);\n        lit = _841;\n        result = _841;\n    }\n    result += _920;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _865 = fa_mesh_fs_params[7].w * length(_533);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_865) * _865), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _915);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
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
            "inst_name": "_136",
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
            "inst_name": "_636",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_shadow_pos;\nlayout(location = 4) in vec4 fa_inst_m0;\nlayout(location = 5) in vec4 fa_inst_m1;\nlayout(location = 6) in vec4 fa_inst_m2;\nlayout(location = 7) in vec4 fa_inst_m3;\nlayout(location = 8) in vec4 fa_joints;\nlayout(location = 9) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _181 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_181 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_181 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_181 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _84 = cross(model[1].xyz, model[2].xyz);\n    float _90 = (dot(model[0].xyz, _84) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_84 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _90, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _90), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vertex(param_5);\n    vec4 _289 = vec4(param_5.world_pos, 1.0);\n    fa_world_pos = param_5.world_pos;\n    fa_world_normal = param_5.world_normal;\n    fa_world_tangent = param_5.world_tangent;\n    fa_uv = param_5.uv;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _289;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _289;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 4) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _133 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _140 = _133 * fa_mesh_fs_params[2];\n    vec3 _945 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _173 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _178 = _173.xy * fa_mesh_fs_params[6].x;\n        vec3 _962 = _173;\n        _962.x = _178.x;\n        _962.y = _178.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _962;\n        _945 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _196 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_140.xyz, _140.w, _945, clamp(fa_mesh_fs_params[5].x * _196.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _196.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _263 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _263;\n    vec2 suv = (_263.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _967 = p;\n        _967.z = (_967.z * 0.5) + 0.5;\n        p = _967;\n    }\n    else\n    {\n        vec2 _970 = suv;\n        _970.y = 1.0 - _970.y;\n        suv = _970;\n    }\n    bool _290 = suv.x < 0.0;\n    bool _297;\n    if (!_290)\n    {\n        _297 = suv.x > 1.0;\n    }\n    else\n    {\n        _297 = _290;\n    }\n    bool _304;\n    if (!_297)\n    {\n        _304 = suv.y < 0.0;\n    }\n    else\n    {\n        _304 = _297;\n    }\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.y > 1.0;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = p.z > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    if (_318)\n    {\n        return 1.0;\n    }\n    float _332 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _332) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _473 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _476 = _473.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_476 * _476, exp2((-9.27999973297119140625) * ndv)) * _476) + _473.y)) + _473.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _393 = rough * rough;\n    float _426 = 0.60000002384185791015625 * _393;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _393)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _426, 0.0500000007450580596923828125 + _426, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_393 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _895 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _895 = -_895;\n    }\n    vec3 _533 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _534 = normalize(_533);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _895, fa_world_tangent, fa_uv, _534, gl_FrontFacing);\n    Surface _539 = fa_standard_surface(param);\n    vec3 _914 = _539.albedo;\n    float _915 = _539.alpha;\n    vec3 _916 = _539.normal;\n    float _917 = _539.metallic;\n    float _918 = _539.roughness;\n    float _919 = _539.occlusion;\n    vec3 _920 = _539.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _895, fa_world_tangent, fa_uv, _534, gl_FrontFacing);\n    Surface param_2 = _539;\n    surface(param_1, param_2);\n    _914 = param_2.albedo;\n    _915 = param_2.alpha;\n    _916 = param_2.normal;\n    _917 = param_2.metallic;\n    _918 = param_2.roughness;\n    _919 = param_2.occlusion;\n    _920 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _914;\n    }\n    else\n    {\n        vec3 _561 = normalize(_916);\n        float _568 = clamp(_917, 0.0, 1.0);\n        float _572 = clamp(_918, 0.0500000007450580596923828125, 1.0);\n        float _576 = _572 * _572;\n        float _580 = _576 * _576;\n        float _586 = max(dot(_561, _534), 9.9999997473787516355514526367188e-05);\n        vec3 _592 = _914 * (1.0 - _568);\n        vec3 _600 = mix(vec3(0.039999999105930328369140625), _914, vec3(_568));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _592) * _919;\n        int _613 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _613)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _642 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_642)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _659 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _662 = length(_659);\n                l = _659 / vec3(max(_662, 9.9999997473787516355514526367188e-05));\n                float _677 = _662 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _683 = clamp(1.0 - (_677 * _677), 0.0, 1.0);\n                atten = _683 * _683;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _717 = max(dot(_561, l), 0.0);\n            if (_642 && (li == 0))\n            {\n                vec3 param_3 = _895;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _736 = normalize(l + _534);\n            float _741 = max(dot(_561, _736), 0.0);\n            float _754 = ((_741 * _741) * (_580 - 1.0)) + 1.0;\n            lit += (((_592 + (((_600 + ((vec3(1.0) - _600) * pow(1.0 - max(dot(_534, _736), 0.0), 5.0))) * (((_580 / ((3.1415927410125732421875 * _754) * _754)) * (0.5 / max(mix((2.0 * _717) * _586, _717 + _586, _576), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _717))) * fa_lights[li * 1 + 32].xyz) * (_717 * atten));\n        }\n        float param_5 = _572;\n        float param_6 = _586;\n        vec2 _822 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_534, _561);\n        float param_8 = _572;\n        vec3 _840 = lit;\n        vec3 _841 = _840 + ((fa_environment(param_7, param_8) * ((_600 * _822.x) + vec3(_822.y))) * _919);\n        lit = _841;\n        result = _841;\n    }\n    result += _920;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _865 = fa_mesh_fs_params[7].w * length(_533);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_865) * _865), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _915);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_46",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_146",
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
            "inst_name": "_190",
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
            "inst_name": "_136",
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
            "inst_name": "_636",
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _71 = cross(model[1].xyz, model[2].xyz);\n    float _77 = (dot(model[0].xyz, _71) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_71 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _77, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _77), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    vertex(param_5);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_5.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_33",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_133",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _173 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_173 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_173 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_173 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0)\n{\n    vec3 _76 = cross(model[1].xyz, model[2].xyz);\n    float _82 = (dot(model[0].xyz, _76) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_76 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _82, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _82), texcoord0 * fa_mesh_vs_params[8].xy, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    VertexData param_7 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6);\n    vertex(param_7);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_7.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_38",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_138",
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
            "inst_name": "_182",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
