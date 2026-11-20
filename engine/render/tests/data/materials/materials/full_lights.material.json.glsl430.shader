{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "2b1d34c4081522ff96f7837c5aacca244600e83b6880b1a4b151f4ef1649850c",
  "slang": "glsl430",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _116 = fa_world_position(param);\n    v_pos = _116;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _116;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_116, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _72 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_72)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _90 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / vec3(max(_92, 9.9999997473787516355514526367188e-05));\n        float _108 = _92 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _114 = clamp(1.0 - (_108 * _108), 0.0, 1.0);\n        atten = _114 * _114;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _166);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _194 = coord.xyz / vec3(coord.w);\n    vec3 p = _194;\n    vec2 suv = (_194.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _732 = p;\n        _732.z = (_732.z * 0.5) + 0.5;\n        p = _732;\n    }\n    else\n    {\n        vec2 _735 = suv;\n        _735.y = 1.0 - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0;\n    }\n    float _269 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= textureLod(fa_full_shadow_tex_fa_full_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec4 param = coord;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1);\n    vec3 _713 = _352.direction;\n    vec3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4);\n        _710 = _368;\n        _708 = fa_lights[li * 1 + 32].xyz * (_715 * _368);\n    }\n    return LightSample(_713, _708, _715, _710, _352._distance, _718);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _387 = fa_mesh_fs_params[7].w > 0.0;\n    bool _395;\n    if (!_387)\n    {\n        _395 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        vec3 _403 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _410 = dot(_403, fa_mesh_fs_params[9].xyz);\n        bool _414 = fa_mesh_fs_params[9].w > 0.5;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - fa_mesh_fs_params[8].x;\n        if (_427 > 0.0)\n        {\n            float _436 = fa_mesh_fs_params[7].w * _427;\n            float tau = _436 * _436;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (fa_mesh_fs_params[9].y * _410);\n                }\n                else\n                {\n                    _452 = fa_mesh_fs_params[0].y;\n                }\n                float _473 = mix(_452, world_pos.y, clamp(fa_mesh_fs_params[8].x / _415, 0.0, 1.0));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - fa_mesh_fs_params[8].z;\n                float _487 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _490 = _482 <= 0.0;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _498 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _482, 80.0));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = fa_mesh_fs_params[8].y * _482;\n                }\n                else\n                {\n                    _526 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _482, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _551 = _487 <= 0.0;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = fa_mesh_fs_params[8].y * _487;\n                }\n                else\n                {\n                    _559 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _487, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * max(_586, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _624 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _624;\n        vec4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _657.color) * max(dot(_624, _657.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _680 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_680, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "inst_name": "_99",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
            "inst_name": "_631",
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
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _234 = fa_world_position(param);\n    v_pos = _234;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _234;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_234, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _72 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_72)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _90 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / vec3(max(_92, 9.9999997473787516355514526367188e-05));\n        float _108 = _92 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _114 = clamp(1.0 - (_108 * _108), 0.0, 1.0);\n        atten = _114 * _114;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _166);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _194 = coord.xyz / vec3(coord.w);\n    vec3 p = _194;\n    vec2 suv = (_194.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _732 = p;\n        _732.z = (_732.z * 0.5) + 0.5;\n        p = _732;\n    }\n    else\n    {\n        vec2 _735 = suv;\n        _735.y = 1.0 - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0;\n    }\n    float _269 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= textureLod(fa_full_shadow_tex_fa_full_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec4 param = coord;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1);\n    vec3 _713 = _352.direction;\n    vec3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4);\n        _710 = _368;\n        _708 = fa_lights[li * 1 + 32].xyz * (_715 * _368);\n    }\n    return LightSample(_713, _708, _715, _710, _352._distance, _718);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _387 = fa_mesh_fs_params[7].w > 0.0;\n    bool _395;\n    if (!_387)\n    {\n        _395 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        vec3 _403 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _410 = dot(_403, fa_mesh_fs_params[9].xyz);\n        bool _414 = fa_mesh_fs_params[9].w > 0.5;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - fa_mesh_fs_params[8].x;\n        if (_427 > 0.0)\n        {\n            float _436 = fa_mesh_fs_params[7].w * _427;\n            float tau = _436 * _436;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (fa_mesh_fs_params[9].y * _410);\n                }\n                else\n                {\n                    _452 = fa_mesh_fs_params[0].y;\n                }\n                float _473 = mix(_452, world_pos.y, clamp(fa_mesh_fs_params[8].x / _415, 0.0, 1.0));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - fa_mesh_fs_params[8].z;\n                float _487 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _490 = _482 <= 0.0;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _498 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _482, 80.0));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = fa_mesh_fs_params[8].y * _482;\n                }\n                else\n                {\n                    _526 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _482, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _551 = _487 <= 0.0;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = fa_mesh_fs_params[8].y * _487;\n                }\n                else\n                {\n                    _559 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _487, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * max(_586, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _624 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _624;\n        vec4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _657.color) * max(dot(_624, _657.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _680 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_680, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_217",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
            "inst_name": "_631",
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
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    }
  }
}
