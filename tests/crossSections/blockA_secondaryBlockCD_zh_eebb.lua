z_mass = 91.1188
z_width = 2.441404
h_mass = 125.0
h_width = 0.006382339

parameters = {
    energy = 13000.,
}

cuba = {
    verbosity = 3,
    max_eval = 200000000,
    relative_accuracy = 0.005,
    n_start = 1000000,   
    n_increase = 1000000,
    seed = 5468460,        
}

-- 'Flat' transfer functions to integrate over the visible particle's angles

-- First |P|
FlatTransferFunctionOnP.tf_p_4 = {
    ps_point = add_dimension(),
    reco_particle = 'input::particles/4',
    min = 0.,
    max = parameters.energy/2,
}

-- Then Phi
FlatTransferFunctionOnPhi.tf_phi_1 = {
    ps_point = add_dimension(),
    reco_particle = 'input::particles/1',
}
FlatTransferFunctionOnPhi.tf_phi_2 = {
    ps_point = add_dimension(),
    reco_particle = 'input::particles/2',
}
FlatTransferFunctionOnPhi.tf_phi_3 = {
    ps_point = add_dimension(),
    reco_particle = 'input::particles/3',
}
FlatTransferFunctionOnPhi.tf_phi_4 = {
    ps_point = add_dimension(),
    reco_particle = 'tf_p_4::output',
}

-- Finally, do Theta 
FlatTransferFunctionOnTheta.tf_theta_1 = {
    ps_point = add_dimension(),
    reco_particle = 'tf_phi_1::output',
}
FlatTransferFunctionOnTheta.tf_theta_2 = {
    ps_point = add_dimension(),
    reco_particle = 'tf_phi_2::output',
}
FlatTransferFunctionOnTheta.tf_theta_3 = {
    ps_point = add_dimension(),
    reco_particle = 'tf_phi_3::output',
}
FlatTransferFunctionOnTheta.tf_theta_4 = {
    ps_point = add_dimension(),
    reco_particle = 'tf_phi_4::output',
}

BreitWignerGenerator.flatter_h = {
    ps_point = add_dimension(),
    mass = h_mass,
    width = h_width
}

inputs = {
  'tf_theta_1::output',
  'tf_theta_2::output',
  'tf_theta_3::output',
  'tf_theta_4::output',
}

StandardPhaseSpace.phaseSpaceOut = {
    particles = { inputs[4] }
}

SecondaryBlockCD.secBlockCD = {
    s12 = 'flatter_h::s',
    gen_p2 = inputs[4],
    reco_p1 = inputs[3]
}

-- Loop for secondary

Looper.looperCD = {
    solutions = 'secBlockCD::gen_p1',
    path = Path('blocka', 'looperA')
}

    BlockA.blocka = {
        inputs = { inputs[1], inputs[2], 'looperCD::particles/1', inputs[4] },
    }
    
    -- Loop for main block
    
    Looper.looperA = {
        solutions = "blocka::solutions",
        path = Path("initial_state", "me_zh", "integrand")
    }
    
        gen_inputs = { 'looperA::particles/1', 'looperA::particles/2', 'looperCD::particles/1', inputs[4] }
        
        BuildInitialState.initial_state = {
            particles = gen_inputs
        }
    
        jacobians = {
          'tf_p_4::TF_times_jacobian',
          'tf_phi_1::TF_times_jacobian', 'tf_phi_2::TF_times_jacobian', 'tf_phi_3::TF_times_jacobian', 'tf_phi_4::TF_times_jacobian', 
          'tf_theta_1::TF_times_jacobian', 'tf_theta_2::TF_times_jacobian', 'tf_theta_3::TF_times_jacobian', 'tf_theta_4::TF_times_jacobian', 
          'phaseSpaceOut::phase_space',
          'flatter_h::jacobian', 'looperCD::jacobian', 'looperA::jacobian',
        }
    
        MatrixElement.me_zh = {
          pdf = 'CT10nlo',
          pdf_scale = z_mass + h_mass,
    
          matrix_element = 'pp_zh_z_ee_h_bb_sm',
          matrix_element_parameters = {
              card = '../MatrixElements/Cards/param_card_sm_5fs.dat'
          },
    
          initialState = 'initial_state::partons',
    
          particles = {
            inputs = gen_inputs,
            ids = {
              {
                pdg_id = -11,
                me_index = 1,
              },
    
              {
                pdg_id = 11,
                me_index = 2,
              },
    
              {
                pdg_id = 5,
                me_index = 3,
              },
    
              {
                pdg_id = -5,
                me_index = 4,
              },
            }
          },
    
          jacobians = jacobians
        }
    
        DoubleLooperSummer.integrand = {
            input = "me_zh::output"
        }

-- End of loops

integrand("integrand::sum")
