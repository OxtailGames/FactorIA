{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "a75dcd870d51444499f61f3cb2010a1b06d96d8916439ce459176478546f3cd8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _158.world_pos;\n    vec4 _165 = vec4(_267, 1.0);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _165;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _165;\n}\n\nvoid main()\n{\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _157 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _165 = (_157 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _968 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _195 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _200 = _195.xy * fa_mesh_fs_params[6].x;\n        vec3 _985 = _195;\n        _985.x = _200.x;\n        _985.y = _200.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _985;\n        _968 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _218 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_165.xyz, _165.w, _968, clamp(fa_mesh_fs_params[5].x * _218.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _218.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[11].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[11].x), 0.0);\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _284 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _284;\n    vec2 suv = (_284.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _990 = p;\n        _990.z = (_990.z * 0.5) + 0.5;\n        p = _990;\n    }\n    else\n    {\n        vec2 _993 = suv;\n        _993.y = 1.0 - _993.y;\n        suv = _993;\n    }\n    bool _311 = suv.x < 0.0;\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.x > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y < 0.0;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = suv.y > 1.0;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    bool _339;\n    if (!_332)\n    {\n        _339 = p.z > 1.0;\n    }\n    else\n    {\n        _339 = _332;\n    }\n    if (_339)\n    {\n        return 1.0;\n    }\n    float _353 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _353) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _494 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _497 = _494.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_497 * _497, exp2((-9.27999973297119140625) * ndv)) * _497) + _494.y)) + _494.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _414 = rough * rough;\n    float _447 = 0.60000002384185791015625 * _414;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _414)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _447, 0.0500000007450580596923828125 + _447, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_414 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _915 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _915 = -_915;\n    }\n    vec3 _557 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _558 = normalize(_557);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _915, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface _563 = fa_standard_surface(param);\n    vec3 _937 = _563.albedo;\n    float _938 = _563.alpha;\n    vec3 _939 = _563.normal;\n    float _940 = _563.metallic;\n    float _941 = _563.roughness;\n    float _942 = _563.occlusion;\n    vec3 _943 = _563.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _915, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = _563;\n    surface(param_1, param_2);\n    _937 = param_2.albedo;\n    _938 = param_2.alpha;\n    _939 = param_2.normal;\n    _940 = param_2.metallic;\n    _941 = param_2.roughness;\n    _942 = param_2.occlusion;\n    _943 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _937;\n    }\n    else\n    {\n        vec3 _585 = normalize(_939);\n        float _592 = clamp(_940, 0.0, 1.0);\n        float _596 = clamp(_941, 0.0500000007450580596923828125, 1.0);\n        float _600 = _596 * _596;\n        float _604 = _600 * _600;\n        float _610 = max(dot(_585, _558), 9.9999997473787516355514526367188e-05);\n        vec3 _616 = _937 * (1.0 - _592);\n        vec3 _624 = mix(vec3(0.039999999105930328369140625), _937, vec3(_592));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _616) * _942;\n        int _637 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _666 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_666)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _683 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _686 = length(_683);\n                l = _683 / vec3(max(_686, 9.9999997473787516355514526367188e-05));\n                float _701 = _686 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _707 = clamp(1.0 - (_701 * _701), 0.0, 1.0);\n                atten = _707 * _707;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _740 = max(dot(_585, l), 0.0);\n            if (_666 && (li == 0))\n            {\n                vec3 param_3 = _915;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _759 = normalize(l + _558);\n            float _764 = max(dot(_585, _759), 0.0);\n            float _777 = ((_764 * _764) * (_604 - 1.0)) + 1.0;\n            lit += (((_616 + (((_624 + ((vec3(1.0) - _624) * pow(1.0 - max(dot(_558, _759), 0.0), 5.0))) * (((_604 / ((3.1415927410125732421875 * _777) * _777)) * (0.5 / max(mix((2.0 * _740) * _610, _740 + _610, _600), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _740))) * fa_lights[li * 1 + 32].xyz) * (_740 * atten));\n        }\n        float param_5 = _596;\n        float param_6 = _610;\n        vec2 _845 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_558, _585);\n        float param_8 = _596;\n        vec3 _863 = lit;\n        vec3 _864 = _863 + ((fa_environment(param_7, param_8) * ((_624 * _845.x) + vec3(_845.y))) * _942);\n        lit = _864;\n        result = _864;\n    }\n    result += _943;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _888 = fa_mesh_fs_params[7].w * length(_557);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_888) * _888), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _938);\n}\n\n",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_121",
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
            "inst_name": "_660",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_172 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_172 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_172 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _271.world_pos;\n    vec4 _278 = vec4(_388, 1.0);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _278;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _278;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[12];\nuniform vec4 fa_lights[96];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    vec3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    vec3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    vec3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 _157 = texture(fa_tex_fa_smp, i.uv);\n    vec4 _165 = (_157 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _968 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        vec3 _195 = (texture(fa_normal_tex_fa_smp, i.uv).xyz * 2.0) - vec3(1.0);\n        vec2 _200 = _195.xy * fa_mesh_fs_params[6].x;\n        vec3 _985 = _195;\n        _985.x = _200.x;\n        _985.y = _200.y;\n        SurfaceInput param = i;\n        vec3 param_1 = _985;\n        _968 = fa_tangent_normal(param, param_1);\n    }\n    vec4 _218 = texture(fa_mr_tex_fa_smp, i.uv);\n    return Surface(_165.xyz, _165.w, _968, clamp(fa_mesh_fs_params[5].x * _218.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _218.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (texture(fa_occlusion_tex_fa_smp, i.uv).x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * texture(fa_emissive_tex_fa_smp, i.uv).xyz));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[11].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[11].x), 0.0);\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _284 = fa_shadow_pos.xyz / vec3(fa_shadow_pos.w);\n    vec3 p = _284;\n    vec2 suv = (_284.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[8].z > 0.5)\n    {\n        vec3 _990 = p;\n        _990.z = (_990.z * 0.5) + 0.5;\n        p = _990;\n    }\n    else\n    {\n        vec2 _993 = suv;\n        _993.y = 1.0 - _993.y;\n        suv = _993;\n    }\n    bool _311 = suv.x < 0.0;\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.x > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y < 0.0;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = suv.y > 1.0;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    bool _339;\n    if (!_332)\n    {\n        _339 = p.z > 1.0;\n    }\n    else\n    {\n        _339 = _332;\n    }\n    if (_339)\n    {\n        return 1.0;\n    }\n    float _353 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _353) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[8].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _494 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _497 = _494.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_497 * _497, exp2((-9.27999973297119140625) * ndv)) * _497) + _494.y)) + _494.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _414 = rough * rough;\n    float _447 = 0.60000002384185791015625 * _414;\n    return mix(mix(fa_mesh_fs_params[10].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[10].xyz, fa_mesh_fs_params[9].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _414)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _447, 0.0500000007450580596923828125 + _447, d.y))), ((fa_mesh_fs_params[9].xyz + fa_mesh_fs_params[10].xyz) * 0.5) * 0.800000011920928955078125, vec3(_414 * 0.60000002384185791015625));\n}\n\nvoid main()\n{\n    vec3 _915 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _915 = -_915;\n    }\n    vec3 _557 = fa_mesh_fs_params[0].xyz - fa_world_pos;\n    vec3 _558 = normalize(_557);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _915, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface _563 = fa_standard_surface(param);\n    vec3 _937 = _563.albedo;\n    float _938 = _563.alpha;\n    vec3 _939 = _563.normal;\n    float _940 = _563.metallic;\n    float _941 = _563.roughness;\n    float _942 = _563.occlusion;\n    vec3 _943 = _563.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _915, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = _563;\n    surface(param_1, param_2);\n    _937 = param_2.albedo;\n    _938 = param_2.alpha;\n    _939 = param_2.normal;\n    _940 = param_2.metallic;\n    _941 = param_2.roughness;\n    _942 = param_2.occlusion;\n    _943 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _937;\n    }\n    else\n    {\n        vec3 _585 = normalize(_939);\n        float _592 = clamp(_940, 0.0, 1.0);\n        float _596 = clamp(_941, 0.0500000007450580596923828125, 1.0);\n        float _600 = _596 * _596;\n        float _604 = _600 * _600;\n        float _610 = max(dot(_585, _558), 9.9999997473787516355514526367188e-05);\n        vec3 _616 = _937 * (1.0 - _592);\n        vec3 _624 = mix(vec3(0.039999999105930328369140625), _937, vec3(_592));\n        vec3 lit = (fa_mesh_fs_params[1].xyz * _616) * _942;\n        int _637 = int(fa_mesh_fs_params[8].x);\n        vec3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _666 = fa_lights[li * 1 + 32].w < 0.5;\n            if (_666)\n            {\n                l = normalize(fa_lights[li * 1 + 0].xyz);\n            }\n            else\n            {\n                vec3 _683 = fa_lights[li * 1 + 0].xyz - fa_world_pos;\n                float _686 = length(_683);\n                l = _683 / vec3(max(_686, 9.9999997473787516355514526367188e-05));\n                float _701 = _686 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n                float _707 = clamp(1.0 - (_701 * _701), 0.0, 1.0);\n                atten = _707 * _707;\n                if (fa_lights[li * 1 + 32].w > 1.5)\n                {\n                    atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n                }\n            }\n            float _740 = max(dot(_585, l), 0.0);\n            if (_666 && (li == 0))\n            {\n                vec3 param_3 = _915;\n                vec3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            vec3 _759 = normalize(l + _558);\n            float _764 = max(dot(_585, _759), 0.0);\n            float _777 = ((_764 * _764) * (_604 - 1.0)) + 1.0;\n            lit += (((_616 + (((_624 + ((vec3(1.0) - _624) * pow(1.0 - max(dot(_558, _759), 0.0), 5.0))) * (((_604 / ((3.1415927410125732421875 * _777) * _777)) * (0.5 / max(mix((2.0 * _740) * _610, _740 + _610, _600), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _740))) * fa_lights[li * 1 + 32].xyz) * (_740 * atten));\n        }\n        float param_5 = _596;\n        float param_6 = _610;\n        vec2 _845 = fa_env_brdf(param_5, param_6);\n        vec3 param_7 = reflect(-_558, _585);\n        float param_8 = _596;\n        vec3 _863 = lit;\n        vec3 _864 = _863 + ((fa_environment(param_7, param_8) * ((_624 * _845.x) + vec3(_845.y))) * _942);\n        lit = _864;\n        result = _864;\n    }\n    result += _943;\n    if (fa_mesh_fs_params[7].w > 0.0)\n    {\n        float _888 = fa_mesh_fs_params[7].w * length(_557);\n        result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp((-_888) * _888), 0.0, 1.0)));\n    }\n    fa_frag_color = vec4(result, _938);\n}\n\n",
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
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_121",
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
            "inst_name": "_660",
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
