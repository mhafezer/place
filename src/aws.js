import { API } from '@aws-amplify/api'
import { Auth} from '@aws-amplify/auth'
import config from './aws-exports'


API.configure(config)
Auth.configure(config)

export { API, Auth }